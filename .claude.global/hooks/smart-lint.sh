#!/usr/bin/env bash

# Smart Lint Hook for JavaScript, TypeScript, Vue, Shell, and Makefile files
# This hook runs ESLint on JS/TS/Vue files, ShellCheck on shell scripts, and syntax checking on Makefiles, providing clear feedback to Claude

# Don't use strict error handling - we want to capture and report errors
set -u

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Caching infrastructure for performance optimization
declare -A ESLINT_CONFIG_CACHE
declare -A TYPESCRIPT_CONFIG_CACHE  
declare -A TOOL_AVAILABILITY_CACHE
declare -A ABSOLUTE_PATH_CACHE
declare -A NUXT_CONFIG_CACHE

# ============================================================================
# HOOK INPUT PROTOCOL (Claude Code Official)
# ============================================================================
# This script follows Claude Code's PostToolUse hook protocol:
# - Input: JSON via stdin with structure:
#   {
#     "tool_name": "Edit|Write|MultiEdit",
#     "tool_input": {
#       "file_path": "/absolute/path/to/file.ts",
#       "old_string": "...",
#       "new_string": "..."
#     }
#   }
# - Output: Exit code 0 (success) or 2 (blocking errors)
# - Reference: https://docs.claude.com/en/docs/claude-code/hooks.md
# ============================================================================

# Hook input variables
HOOK_INPUT=""
HOOK_FILE_PATH=""
HOOK_TOOL_NAME=""

# Read JSON from stdin (primary data source for PostToolUse hooks)
read_hook_stdin() {
    # Check if stdin is available (not a terminal)
    if [[ ! -t 0 ]]; then
        # Read entire stdin
        HOOK_INPUT="$(cat 2>/dev/null || true)"

        # Extract data using jq if available
        if command -v jq >/dev/null 2>&1 && [[ -n "$HOOK_INPUT" ]]; then
            # Validate JSON first
            if echo "$HOOK_INPUT" | jq empty 2>/dev/null; then
                HOOK_TOOL_NAME="$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
                HOOK_FILE_PATH="$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

                # Validate extracted path
                if [[ "$HOOK_FILE_PATH" == "null" || -z "$HOOK_FILE_PATH" ]]; then
                    HOOK_FILE_PATH=""
                fi
            fi
        fi
    fi
}

# Call stdin reader at initialization
read_hook_stdin

# File to store linting errors from all tools
LINT_ERRORS_FILE="$HOME/.claude/smart_lint_errors.json"

# Resource limits and security constraints
readonly MAX_FILES_PER_BATCH=50
readonly COMMAND_TIMEOUT=30
readonly MAX_FILE_SIZE_MB=10
readonly MAX_OUTPUT_LINES=100

# Initialize error tracking
ERRORS_FOUND=false
ERROR_ENTRIES=()
BLOCKING_ERRORS=()

# Helper function to get absolute path with caching (secure implementation)
get_absolute_path() {
    local file_path="$1"
    
    # Check cache first
    if [[ -n "${ABSOLUTE_PATH_CACHE[$file_path]:-}" ]]; then
        echo "${ABSOLUTE_PATH_CACHE[$file_path]}"
        return 0
    fi
    
    local absolute_path
    if [[ "$file_path" = /* ]]; then
        absolute_path="$file_path"
    else
        # Use realpath if available for secure path resolution
        if command -v realpath >/dev/null 2>&1; then
            absolute_path="$(realpath "$file_path" 2>/dev/null)" || absolute_path="$file_path"
        else
            # Secure fallback without command substitution in user-controlled paths
            local dir_path file_name
            dir_path="$(dirname "$file_path")"
            file_name="$(basename "$file_path")"
            
            # Validate directory path before cd
            if [[ -d "$dir_path" ]]; then
                local resolved_dir
                resolved_dir="$(cd "$dir_path" 2>/dev/null && pwd -P)" || resolved_dir="$dir_path"
                absolute_path="$resolved_dir/$file_name"
            else
                absolute_path="$file_path"
            fi
        fi
    fi
    
    # Cache the result
    ABSOLUTE_PATH_CACHE[$file_path]="$absolute_path"
    echo "$absolute_path"
}

# Secure function to check if file is a shell script by examining shebang
is_shell_script() {
    local file_path="$1"
    
    # Validate file exists and is readable
    if [[ ! -f "$file_path" || ! -r "$file_path" ]]; then
        return 1
    fi
    
    # Safely read first line without command substitution
    local first_line
    if ! first_line=$(head -n 1 "$file_path" 2>/dev/null); then
        return 1
    fi
    
    # Check if first line is a shell shebang (without regex that could be exploited)
    case "$first_line" in
        "#!/bin/sh"|"#!/bin/bash"|"#!/bin/zsh"|"#!/usr/bin/sh"|"#!/usr/bin/bash"|"#!/usr/bin/zsh")
            return 0
            ;;
        "#!/usr/bin/env sh"|"#!/usr/bin/env bash"|"#!/usr/bin/env zsh")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Comprehensive input sanitization for file paths
sanitize_file_path() {
    local file_path="$1"
    
    # Check for null or empty input
    if [[ -z "$file_path" ]]; then
        return 1
    fi
    
    # Check for specific dangerous control characters (newline, tab, null, etc.)
    if [[ "$file_path" == *$'\n'* ]] || [[ "$file_path" == *$'\r'* ]] || [[ "$file_path" == *$'\t'* ]]; then
        return 1
    fi
    
    # Check for dangerous shell metacharacters (but allow $ in filenames like Next.js routes)
    if [[ "$file_path" == *'`'* ]] || [[ "$file_path" == *';'* ]]; then
        return 1
    fi
    
    # Check specifically for dangerous command substitution patterns
    if [[ "$file_path" == *\$\{* ]] || [[ "$file_path" == *\$\(* ]]; then
        return 1
    fi
    
    # Check for process substitution patterns
    if [[ "$file_path" == *'<('* ]] || [[ "$file_path" == *'>('* ]]; then
        return 1
    fi
    
    # Check for dangerous shell redirection at start of path
    if [[ "$file_path" == '<'* ]] || [[ "$file_path" == '>'* ]]; then
        return 1
    fi
    
    # Check for null bytes (which could truncate validation)
    # Use length-based comparison to avoid false positives
    local byte_count
    byte_count=$(printf '%s' "$file_path" | wc -c)
    if [[ ${#file_path} -ne $byte_count ]]; then
        return 1
    fi
    
    # Prevent extremely long paths (potential DoS)
    if [[ ${#file_path} -gt 4096 ]]; then
        return 1
    fi
    
    # Check for dangerous directory traversal patterns (but allow simple relative paths)
    if [[ "$file_path" == *'../..'* ]] && [[ "$file_path" == *'../../..'* ]]; then
        return 1
    fi
    
    return 0
}

# Run command with timeout, sandboxing, and proper shell escaping
run_with_timeout() {
    local timeout_seconds="$1"
    shift
    local cmd=("$@")
    
    # Create restricted environment for sandboxing
    # Include fnm multishell path if available to use correct Node.js version
    local fnm_path=""
    if [[ -n "${FNM_MULTISHELL_PATH:-}" && -d "${FNM_MULTISHELL_PATH}/bin" ]]; then
        fnm_path="${FNM_MULTISHELL_PATH}/bin:"
    fi
    
    local -a env_vars=(
        "PATH=${fnm_path}/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        "HOME=$HOME"
        "USER=${USER:-unknown}"
        "LANG=${LANG:-C}"
        "LC_ALL=C"
        "FNM_MULTISHELL_PATH=${FNM_MULTISHELL_PATH:-}"
        "FNM_DIR=${FNM_DIR:-}"
        "NODE_PATH=${NODE_PATH:-}"
        "PWD=$(pwd)"
    )
    
    # Handle npx commands specially - they need to be split properly
    local final_cmd=()
    if [[ "${cmd[0]}" == *"npx --prefix"* ]]; then
        # Split npx command into proper arguments
        read -ra final_cmd <<< "${cmd[0]}"
        # Add remaining arguments
        for ((i=1; i<${#cmd[@]}; i++)); do
            final_cmd+=("${cmd[i]}")
        done
    else
        final_cmd=("${cmd[@]}")
    fi
    
    # Use timeout command with restricted environment if available
    if command -v timeout >/dev/null 2>&1; then
        env -i "${env_vars[@]}" timeout "$timeout_seconds" "${final_cmd[@]}" 2>&1
    else
        # Fallback for systems without timeout command
        env -i "${env_vars[@]}" "${final_cmd[@]}" 2>&1
    fi
}

# Safely sanitize strings for JSON to prevent injection
sanitize_for_json() {
    local input="$1"
    local max_length=8192
    
    # Truncate extremely long input to prevent DoS
    if [[ ${#input} -gt $max_length ]]; then
        input="${input:0:$max_length}... (truncated)"
    fi
    
    # Remove null bytes and other dangerous characters
    input="${input//$'\0'/}"
    input="${input//$'\r'/}"
    
    # Use printf to safely escape the string for jq
    printf '%s' "$input"
}

# Function to find package.json with specific dependency
find_package_json_with_dependency() {
    local file_path="$1"
    local dependency="$2"
    local dir
    dir="$(dirname "$file_path")"
    
    local search_dir="$dir"
    while [[ "$search_dir" != "/" ]]; do
        if [[ -f "$search_dir/package.json" ]]; then
            # Check if package.json contains the dependency
            if jq -e --arg dep "$dependency" '.dependencies[$dep] // .devDependencies[$dep] // .peerDependencies[$dep]' "$search_dir/package.json" >/dev/null 2>&1; then
                echo "$search_dir"
                return 0
            fi
        fi
        search_dir="$(dirname "$search_dir")"
    done
    return 1
}

# Function to get project's Node.js version from various sources
get_project_node_version() {
    local project_dir="$1"
    
    # Check .nvmrc
    if [[ -f "$project_dir/.nvmrc" ]]; then
        tr -d '\n\r' < "$project_dir/.nvmrc"
        return 0
    fi
    
    # Check .node-version
    if [[ -f "$project_dir/.node-version" ]]; then
        tr -d '\n\r' < "$project_dir/.node-version"
        return 0
    fi
    
    # Check package.json engines.node
    if [[ -f "$project_dir/package.json" ]]; then
        local node_version
        node_version=$(jq -r '.engines.node // empty' "$project_dir/package.json" 2>/dev/null)
        if [[ -n "$node_version" && "$node_version" != "null" ]]; then
            echo "$node_version"
            return 0
        fi
    fi
    
    return 1
}

# Function to ensure correct Node.js version is being used
setup_node_environment() {
    local project_dir="$1"
    local required_node_version
    
    if required_node_version=$(get_project_node_version "$project_dir"); then
        echo -e "${BLUE}📦 Project requires Node.js version: $required_node_version${NC}"
        
        # If fnm is available, try to use the correct version
        if command -v fnm >/dev/null 2>&1; then
            if fnm use "$required_node_version" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Using Node.js version: $(node --version)${NC}"
                return 0
            else
                echo -e "${YELLOW}⚠ fnm cannot use Node.js $required_node_version, using current: $(node --version)${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ fnm not found, using system Node: $(node --version)${NC}"
        fi
    fi
    
    return 1
}

# Function to find the nearest ESLint config with caching
find_eslint_config() {
    local file_path="$1"
    local dir
    dir="$(dirname "$file_path")"
    
    # Check cache first
    if [[ -n "${ESLINT_CONFIG_CACHE[$dir]:-}" ]]; then
        if [[ "${ESLINT_CONFIG_CACHE[$dir]}" == "NOT_FOUND" ]]; then
            return 1
        else
            echo "${ESLINT_CONFIG_CACHE[$dir]}"
            return 0
        fi
    fi
    
    # Skip if file is in .nuxt directory
    if [[ "$file_path" =~ /\.nuxt/ ]]; then
        ESLINT_CONFIG_CACHE[$dir]="NOT_FOUND"
        return 1
    fi
    
    local search_dir="$dir"
    while [[ "$search_dir" != "/" ]]; do
        # Skip if we've reached a .nuxt directory
        if [[ "$(basename "$search_dir")" == ".nuxt" ]]; then
            ESLINT_CONFIG_CACHE[$dir]="NOT_FOUND"
            return 1
        fi
        
        # Check for various ESLint config files
        for config in ".eslintrc.js" ".eslintrc.cjs" ".eslintrc.json" ".eslintrc.yml" ".eslintrc.yaml" ".eslintrc" "eslint.config.js" "eslint.config.mjs" "eslint.config.cjs"; do
            if [[ -f "$search_dir/$config" ]]; then
                ESLINT_CONFIG_CACHE[$dir]="$search_dir"
                echo "$search_dir"
                return 0
            fi
        done
        
        # Check for eslint config in package.json
        if [[ -f "$search_dir/package.json" ]] && grep -q '"eslintConfig"' "$search_dir/package.json" 2>/dev/null; then
            ESLINT_CONFIG_CACHE[$dir]="$search_dir"
            echo "$search_dir"
            return 0
        fi
        
        search_dir="$(dirname "$search_dir")"
    done
    
    # Cache negative result
    ESLINT_CONFIG_CACHE[$dir]="NOT_FOUND"
    return 1
}

# Function to check if ESLint is available in a directory with caching
check_eslint_available() {
    local dir="$1"
    local file_path="$2"
    local cache_key="eslint:$dir"
    
    # Check cache first
    if [[ -n "${TOOL_AVAILABILITY_CACHE[$cache_key]:-}" ]]; then
        if [[ "${TOOL_AVAILABILITY_CACHE[$cache_key]}" == "NOT_FOUND" ]]; then
            return 1
        else
            echo "${TOOL_AVAILABILITY_CACHE[$cache_key]}"
            return 0
        fi
    fi
    
    # Find project root with eslint dependency
    local project_dir
    if project_dir=$(find_package_json_with_dependency "$file_path" "eslint"); then
        # Setup Node environment for this project
        setup_node_environment "$project_dir" >/dev/null 2>&1 || true
        
        # Prefer npx to respect project version
        if [[ -f "$project_dir/package.json" ]]; then
            # Use npx from the project directory to ensure correct version
            local eslint_cmd="npx --prefix $project_dir eslint"
            TOOL_AVAILABILITY_CACHE[$cache_key]="$eslint_cmd"
            
            # Log version information for debugging
            local version_info
            version_info=$(command cd "$project_dir" && npx eslint --version 2>/dev/null || echo "unknown")
            echo -e "${BLUE}📋 Using ESLint version: $version_info (from $project_dir)${NC}" >&2
            
            echo "$eslint_cmd"
            return 0
        fi
    fi
    
    # Fallback: Check for local eslint binary
    if [[ -f "$dir/node_modules/.bin/eslint" ]]; then
        TOOL_AVAILABILITY_CACHE[$cache_key]="$dir/node_modules/.bin/eslint"
        echo "$dir/node_modules/.bin/eslint"
        return 0
    fi
    
    # Fallback: Check for global eslint (with warning)
    if command -v eslint &> /dev/null; then
        echo -e "${YELLOW}⚠ Using global ESLint (project version preferred)${NC}" >&2
        TOOL_AVAILABILITY_CACHE[$cache_key]="eslint"
        echo "eslint"
        return 0
    fi
    
    # Cache negative result
    TOOL_AVAILABILITY_CACHE[$cache_key]="NOT_FOUND"
    return 1
}

# Function to find the nearest tsconfig.json with caching
find_tsconfig() {
    local file_path="$1"
    local dir
    dir="$(dirname "$file_path")"
    
    # Check cache first
    if [[ -n "${TYPESCRIPT_CONFIG_CACHE[$dir]:-}" ]]; then
        if [[ "${TYPESCRIPT_CONFIG_CACHE[$dir]}" == "NOT_FOUND" ]]; then
            return 1
        else
            echo "${TYPESCRIPT_CONFIG_CACHE[$dir]}"
            return 0
        fi
    fi
    
    # Skip if file is in .nuxt directory
    if [[ "$file_path" =~ /\.nuxt/ ]]; then
        TYPESCRIPT_CONFIG_CACHE[$dir]="NOT_FOUND"
        return 1
    fi
    
    local search_dir="$dir"
    while [[ "$search_dir" != "/" ]]; do
        # Skip if we've reached a .nuxt directory
        if [[ "$(basename "$search_dir")" == ".nuxt" ]]; then
            TYPESCRIPT_CONFIG_CACHE[$dir]="NOT_FOUND"
            return 1
        fi
        
        if [[ -f "$search_dir/tsconfig.json" ]]; then
            TYPESCRIPT_CONFIG_CACHE[$dir]="$search_dir"
            echo "$search_dir"
            return 0
        fi
        search_dir="$(dirname "$search_dir")"
    done
    
    # Cache negative result
    TYPESCRIPT_CONFIG_CACHE[$dir]="NOT_FOUND"
    return 1
}

# Function to find the nearest nuxt.config.* file with caching
find_nuxt_config() {
    local file_path="$1"
    local dir
    dir="$(dirname "$file_path")"
    
    # Check cache first
    if [[ -n "${NUXT_CONFIG_CACHE[$dir]:-}" ]]; then
        if [[ "${NUXT_CONFIG_CACHE[$dir]}" == "NOT_FOUND" ]]; then
            return 1
        else
            echo "${NUXT_CONFIG_CACHE[$dir]}"
            return 0
        fi
    fi
    
    # Skip if file is in .nuxt directory
    if [[ "$file_path" =~ /\.nuxt/ ]]; then
        NUXT_CONFIG_CACHE[$dir]="NOT_FOUND"
        return 1
    fi
    
    local search_dir="$dir"
    while [[ "$search_dir" != "/" ]]; do
        # Check for various Nuxt config files
        for config in "nuxt.config.ts" "nuxt.config.js" "nuxt.config.mjs" "nuxt.config.cjs"; do
            if [[ -f "$search_dir/$config" ]]; then
                NUXT_CONFIG_CACHE[$dir]="$search_dir"
                echo "$search_dir"
                return 0
            fi
        done
        search_dir="$(dirname "$search_dir")"
    done
    
    # Cache negative result
    NUXT_CONFIG_CACHE[$dir]="NOT_FOUND"
    return 1
}

# Function to check if TypeScript compiler is available with caching
check_typescript_available() {
    local dir="$1"
    local is_vue_file="$2"
    local file_path="$3"
    local cache_key="typescript:$dir:$is_vue_file"
    
    # Check cache first
    if [[ -n "${TOOL_AVAILABILITY_CACHE[$cache_key]:-}" ]]; then
        if [[ "${TOOL_AVAILABILITY_CACHE[$cache_key]}" == "NOT_FOUND" ]]; then
            return 1
        else
            echo "${TOOL_AVAILABILITY_CACHE[$cache_key]}"
            return 0
        fi
    fi
    
    # Find project root with typescript dependency
    local project_dir
    local dep_name="typescript"
    if [[ "$is_vue_file" == "true" ]]; then
        # For Vue files, also check for vue-tsc
        if project_dir=$(find_package_json_with_dependency "$file_path" "vue-tsc"); then
            dep_name="vue-tsc"
        elif project_dir=$(find_package_json_with_dependency "$file_path" "typescript"); then
            dep_name="typescript"
        fi
    else
        project_dir=$(find_package_json_with_dependency "$file_path" "typescript")
    fi
    
    if [[ -n "$project_dir" ]]; then
        # Setup Node environment for this project
        setup_node_environment "$project_dir" >/dev/null 2>&1 || true
        
        # Use npx to respect project version, but verify installation first
        if [[ "$is_vue_file" == "true" && "$dep_name" == "vue-tsc" ]]; then
            # Verify vue-tsc is actually available before proceeding
            if command cd "$project_dir" && npx vue-tsc --version >/dev/null 2>&1; then
                local tsc_cmd="npx --prefix $project_dir vue-tsc"
                TOOL_AVAILABILITY_CACHE[$cache_key]="$tsc_cmd"
                
                # Log version information for debugging
                local version_info
                version_info=$(command cd "$project_dir" && npx vue-tsc --version 2>/dev/null || echo "unknown")
                echo -e "${BLUE}📋 Using vue-tsc version: $version_info (from $project_dir)${NC}" >&2
                
                echo "$tsc_cmd"
                return 0
            fi
        else
            # Verify tsc is actually available before proceeding
            if command cd "$project_dir" && npx tsc --version >/dev/null 2>&1; then
                local tsc_cmd="npx --prefix $project_dir tsc"
                TOOL_AVAILABILITY_CACHE[$cache_key]="$tsc_cmd"
                
                # Log version information for debugging
                local version_info
                version_info=$(command cd "$project_dir" && npx tsc --version 2>/dev/null || echo "unknown")
                echo -e "${BLUE}📋 Using TypeScript version: $version_info (from $project_dir)${NC}" >&2
                
                echo "$tsc_cmd"
                return 0
            fi
        fi
    fi
    
    # Fallback: For Vue files, prefer vue-tsc
    if [[ "$is_vue_file" == "true" ]]; then
        # Check for local vue-tsc
        if [[ -f "$dir/node_modules/.bin/vue-tsc" ]]; then
            TOOL_AVAILABILITY_CACHE[$cache_key]="$dir/node_modules/.bin/vue-tsc"
            echo "$dir/node_modules/.bin/vue-tsc"
            return 0
        fi
        
        # Check for global vue-tsc
        if command -v vue-tsc &> /dev/null; then
            echo -e "${YELLOW}⚠ Using global vue-tsc (project version preferred)${NC}" >&2
            TOOL_AVAILABILITY_CACHE[$cache_key]="vue-tsc"
            echo "vue-tsc"
            return 0
        fi
    fi
    
    # Fallback: Check for local tsc
    if [[ -f "$dir/node_modules/.bin/tsc" ]]; then
        TOOL_AVAILABILITY_CACHE[$cache_key]="$dir/node_modules/.bin/tsc"
        echo "$dir/node_modules/.bin/tsc"
        return 0
    fi
    
    # Fallback: Check for global tsc
    if command -v tsc &> /dev/null; then
        echo -e "${YELLOW}⚠ Using global TypeScript (project version preferred)${NC}" >&2
        TOOL_AVAILABILITY_CACHE[$cache_key]="tsc"
        echo "tsc"
        return 0
    fi
    
    # Cache negative result
    TOOL_AVAILABILITY_CACHE[$cache_key]="NOT_FOUND"
    return 1
}

# Function to check Makefiles
check_makefile() {
    local file_path="$1"
    local file_name
    file_name="$(basename "$file_path")"
    
    # Get absolute path using cached helper
    local absolute_path
    absolute_path="$(get_absolute_path "$file_path")"
    
    echo -e "${BLUE}→ Checking Makefile $file_name${NC}"
    
    # Check basic syntax with make --dry-run
    local output
    local temp_dir
    
    # Create secure temporary directory
    if ! temp_dir=$(mktemp -d 2>/dev/null); then
        echo -e "${YELLOW}⚠ Could not create temporary directory for $file_name${NC}"
        return 0
    fi
    
    # Set restrictive permissions immediately
    chmod 700 "$temp_dir" || {
        rm -rf "$temp_dir" 2>/dev/null
        echo -e "${YELLOW}⚠ Could not secure temporary directory for $file_name${NC}"
        return 0
    }
    
    # Set up cleanup trap with error handling
    cleanup_temp_dir() {
        if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
            rm -rf "$temp_dir" 2>/dev/null || true
        fi
    }
    trap cleanup_temp_dir EXIT
    
    # Validate source file before copying
    if [[ ! -f "$absolute_path" || ! -r "$absolute_path" ]]; then
        echo -e "${YELLOW}⚠ Cannot read source file $file_name${NC}"
        cleanup_temp_dir
        return 0
    fi
    
    # Copy Makefile to temp directory first, then validate size (prevent TOCTOU race condition)
    if ! cp "$absolute_path" "$temp_dir/Makefile" 2>/dev/null; then
        echo -e "${YELLOW}⚠ Could not copy $file_name for checking${NC}"
        cleanup_temp_dir
        return 0
    fi
    
    # Check size of copied file to prevent DoS attacks
    local copied_size
    copied_size=$(stat -f%z "$temp_dir/Makefile" 2>/dev/null || stat -c%s "$temp_dir/Makefile" 2>/dev/null || echo 0)
    if [[ $copied_size -gt 1048576 ]]; then
        echo -e "${YELLOW}⚠ Makefile $file_name too large (${copied_size} bytes), skipping${NC}"
        cleanup_temp_dir
        return 0
    fi
    
    # Run make dry-run to check syntax with timeout
    if output=$(command cd "$temp_dir" && run_with_timeout "$COMMAND_TIMEOUT" make -n); then
        echo -e "${GREEN}✓ $file_name passed syntax checking${NC}"
        return 0
    else
        echo -e "${RED}❌ $file_name has Makefile syntax errors:${NC}" >&2
        
        # Show first 10 lines of output (Makefile errors are usually verbose)
        echo "$output" | head -10 >&2
        if [[ $(echo "$output" | wc -l) -gt 10 ]]; then
            echo -e "${YELLOW}... (truncated, showing first 10 lines)${NC}" >&2
        fi
        
        # Store error for JSON output
        local session_id="${CLAUDE_SESSION_ID:-unknown}"
        local error_json
        error_json=$(jq -n \
            --arg file "$(sanitize_for_json "$absolute_path")" \
            --arg errors "$(sanitize_for_json "Makefile: $output")" \
            --arg session "$(sanitize_for_json "$session_id")" \
            '{file_path: $file, errors: $errors, session_id: $session}')
        ERROR_ENTRIES+=("$error_json")
        
        BLOCKING_ERRORS+=("$file_name has Makefile syntax errors")
        ERRORS_FOUND=true
        return 1
    fi
}

# Function to run ShellCheck on shell scripts
check_shell_script() {
    local file_path="$1"
    local file_name
    file_name="$(basename "$file_path")"
    
    # Get absolute path using cached helper
    local absolute_path
    absolute_path="$(get_absolute_path "$file_path")"
    
    echo -e "${BLUE}→ Shell checking $file_name${NC}"
    
    # Check if ShellCheck is available
    if ! command -v shellcheck &> /dev/null; then
        echo -e "${YELLOW}⚠ ShellCheck not installed${NC}"
        echo -e "${YELLOW}  Install: brew install shellcheck (macOS) or apt-get install shellcheck (Ubuntu)${NC}"
        return 0
    fi
    
    # Additional security: validate file content before ShellCheck execution
    local first_line
    if ! first_line=$(head -n 1 "$absolute_path" 2>/dev/null); then
        echo -e "${YELLOW}⚠ Could not read $file_name for validation${NC}"
        return 0
    fi
    
    # Verify it's actually a shell script by checking shebang or extension
    local is_valid_shell_script=false
    local is_zsh_file=false
    
    if [[ "$file_path" =~ \.zsh$ ]]; then
        is_valid_shell_script=true
        is_zsh_file=true
    elif [[ "$file_path" =~ \.(sh|bash)$ ]]; then
        is_valid_shell_script=true
    elif is_shell_script "$absolute_path"; then
        is_valid_shell_script=true
        # Check if it's a zsh script by shebang
        if [[ "$first_line" =~ zsh ]]; then
            is_zsh_file=true
        fi
    fi
    
    if [[ "$is_valid_shell_script" != "true" ]]; then
        echo -e "${YELLOW}⚠ $file_name does not appear to be a shell script, skipping${NC}"
        return 0
    fi
    
    # Use appropriate checker based on shell type
    local output
    
    if [[ "$is_zsh_file" == "true" ]]; then
        # Use zsh -n for zsh files
        if ! command -v zsh &> /dev/null; then
            echo -e "${YELLOW}⚠ zsh not available for checking $file_name${NC}"
            return 0
        fi
        
        if output=$(run_with_timeout "$COMMAND_TIMEOUT" zsh -n "$absolute_path"); then
            echo -e "${GREEN}✓ $file_name passed zsh syntax checking${NC}"
            return 0
        else
            echo -e "${RED}❌ $file_name has zsh syntax errors:${NC}" >&2
            
            # Show first 20 lines of output
            echo "$output" | head -20 >&2
            if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
                echo -e "${YELLOW}... (truncated, showing first 20 lines)${NC}" >&2
            fi
            
            # Store error for JSON output
            local session_id="${CLAUDE_SESSION_ID:-unknown}"
            local error_json
            error_json=$(jq -n \
                --arg file "$(sanitize_for_json "$absolute_path")" \
                --arg errors "$(sanitize_for_json "zsh syntax: $output")" \
                --arg session "$(sanitize_for_json "$session_id")" \
                '{file_path: $file, errors: $errors, session_id: $session}')
            ERROR_ENTRIES+=("$error_json")
            
            BLOCKING_ERRORS+=("$file_name has zsh syntax errors")
            ERRORS_FOUND=true
            return 1
        fi
    else
        # Use ShellCheck for bash/sh files
        if ! command -v shellcheck &> /dev/null; then
            echo -e "${YELLOW}⚠ ShellCheck not installed${NC}"
            echo -e "${YELLOW}  Install: brew install shellcheck (macOS) or apt-get install shellcheck (Ubuntu)${NC}"
            return 0
        fi
        
        if output=$(run_with_timeout "$COMMAND_TIMEOUT" shellcheck "$absolute_path"); then
            echo -e "${GREEN}✓ $file_name passed shell checking${NC}"
            return 0
        else
            echo -e "${RED}❌ $file_name has shell script errors:${NC}" >&2
            
            # Show first 20 lines of output
            echo "$output" | head -20 >&2
            if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
                echo -e "${YELLOW}... (truncated, showing first 20 lines)${NC}" >&2
            fi
            
            # Store error for JSON output
            local session_id="${CLAUDE_SESSION_ID:-unknown}"
            local error_json
            error_json=$(jq -n \
                --arg file "$(sanitize_for_json "$absolute_path")" \
                --arg errors "$(sanitize_for_json "ShellCheck: $output")" \
                --arg session "$(sanitize_for_json "$session_id")" \
                '{file_path: $file, errors: $errors, session_id: $session}')
            ERROR_ENTRIES+=("$error_json")
            
            BLOCKING_ERRORS+=("$file_name has ShellCheck errors")
            ERRORS_FOUND=true
            return 1
        fi
    fi
}

# Function to run TypeScript type checking on a file
check_typescript() {
    local file_path="$1"
    local file_name
    file_name="$(basename "$file_path")"
    local is_vue_file="false"
    
    # Check if it's a Vue file
    if [[ "$file_path" =~ \.vue$ ]]; then
        is_vue_file="true"
    fi
    
    # Get absolute path using cached helper
    local absolute_path
    absolute_path="$(get_absolute_path "$file_path")"
    
    # Check if this file is in a Nuxt project
    if nuxt_root=$(find_nuxt_config "$absolute_path"); then
        echo -e "${BLUE}→ Detected Nuxt project for $file_name${NC}"
        
        # Check if .nuxt directory exists
        if [[ -d "$nuxt_root/.nuxt" ]]; then
            echo -e "${BLUE}→ Running Nuxt type checking for $file_name${NC}"
            
            # Run nuxi typecheck
            local output
            # Change to Nuxt root for proper context
            command cd "$nuxt_root" 2>/dev/null || true
            
            if output=$(run_with_timeout "$COMMAND_TIMEOUT" npx nuxi typecheck 2>&1); then
                echo -e "${GREEN}✓ $file_name passed Nuxt type checking${NC}"
                return 0
            else
                # Check if the error is related to the current file
                if echo "$output" | grep -q "$file_name"; then
                    echo -e "${RED}❌ $file_name has type errors:${NC}" >&2
                    
                    # Extract relevant errors for this file
                    local relevant_errors
                    relevant_errors=$(echo "$output" | grep -A 2 -B 2 "$file_name" | head -40)
                    echo "$relevant_errors" >&2
                    
                    # Store error for JSON output
                    local session_id="${CLAUDE_SESSION_ID:-unknown}"
                    local error_json
                    error_json=$(jq -n \
                        --arg file "$(sanitize_for_json "$absolute_path")" \
                        --arg errors "$(sanitize_for_json "Nuxt TypeScript: $relevant_errors")" \
                        --arg session "$(sanitize_for_json "$session_id")" \
                        '{file_path: $file, errors: $errors, session_id: $session}')
                    ERROR_ENTRIES+=("$error_json")
                    
                    BLOCKING_ERRORS+=("$file_name has Nuxt TypeScript type errors")
                    ERRORS_FOUND=true
                    return 1
                else
                    # Errors exist but not in this file
                    echo -e "${YELLOW}⚠ Nuxt project has type errors (not in $file_name)${NC}"
                    return 0
                fi
            fi
        else
            echo -e "${YELLOW}⚠ Skipping TypeScript for $file_name (.nuxt not built yet)${NC}"
            echo -e "${YELLOW}  Run 'npm run dev' or 'npm run build' to enable type checking${NC}"
            return 0  # Don't block on this
        fi
    fi
    
    # Not a Nuxt project - continue with regular TypeScript checking
    echo -e "${BLUE}→ Type checking $file_name${NC}"
    
    # Find the nearest tsconfig.json
    if ! config_dir=$(find_tsconfig "$absolute_path"); then
        echo -e "${YELLOW}⚠ No tsconfig.json found for $file_path${NC}"
        echo -e "${YELLOW}  TypeScript type checking skipped${NC}"
        return 0
    fi
    
    # Check if TypeScript compiler is available
    if ! tsc_cmd=$(check_typescript_available "$config_dir" "$is_vue_file" "$absolute_path"); then
        echo -e "${YELLOW}⚠ TypeScript compiler not found for $file_path${NC}"
        if [[ "$is_vue_file" == "true" ]]; then
            echo -e "${YELLOW}  Install: cd $config_dir && npm install --save-dev vue-tsc typescript${NC}"
        else
            echo -e "${YELLOW}  Install: cd $config_dir && npm install --save-dev typescript${NC}"
        fi
        return 0
    fi
    
    # Run TypeScript type checking
    local output
    
    # Calculate relative path from config directory for better TypeScript resolution
    local file_path_for_tsc
    if [[ "$absolute_path" = "$config_dir"/* ]]; then
        # File is within the config directory - use relative path
        file_path_for_tsc="${absolute_path#"$config_dir"/}"
        # Change to config directory for proper context
        command cd "$config_dir" 2>/dev/null || true
    else
        # File is outside config directory - use absolute path and don't change directory
        file_path_for_tsc="$absolute_path"
    fi
    
    # Run tsc with --noEmit to only check types
    if output=$(run_with_timeout "$COMMAND_TIMEOUT" "$tsc_cmd" --noEmit "$file_path_for_tsc"); then
        echo -e "${GREEN}✓ $file_name passed type checking${NC}"
        return 0
    else
        echo -e "${RED}❌ $file_name has type errors:${NC}" >&2
        
        # Show first 20 lines of output
        echo "$output" | head -20 >&2
        if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
            echo -e "${YELLOW}... (truncated, showing first 20 lines)${NC}" >&2
        fi
        
        # Store error for JSON output
        local session_id="${CLAUDE_SESSION_ID:-unknown}"
        local error_json
        error_json=$(jq -n \
            --arg file "$(sanitize_for_json "$absolute_path")" \
            --arg errors "$(sanitize_for_json "TypeScript: $output")" \
            --arg session "$(sanitize_for_json "$session_id")" \
            '{file_path: $file, errors: $errors, session_id: $session}')
        ERROR_ENTRIES+=("$error_json")
        
        BLOCKING_ERRORS+=("$file_name has TypeScript type errors")
        ERRORS_FOUND=true
        return 1
    fi
}

# Function to run ESLint on multiple files in batch
lint_files_batch() {
    local -a files=("$@")
    local -A files_by_config
    
    # Group files by their ESLint config directory
    for file in "${files[@]}"; do
        local absolute_path
        absolute_path="$(get_absolute_path "$file")"
        
        if config_dir=$(find_eslint_config "$absolute_path"); then
            # Add file to the group for this config
            if [[ -n "${files_by_config[$config_dir]:-}" ]]; then
                files_by_config[$config_dir]+=" $absolute_path"
            else
                files_by_config[$config_dir]="$absolute_path"
            fi
        else
            # Handle files without ESLint config individually
            echo -e "${YELLOW}⚠ No ESLint config found for $file${NC}"
            echo -e "${YELLOW}  Consider adding .eslintrc.js or eslint.config.js to your project${NC}"
        fi
    done
    
    # Process each config group with resource limits
    for config_dir in "${!files_by_config[@]}"; do
        local config_files="${files_by_config[$config_dir]}"
        local -a file_array
        read -ra file_array <<< "$config_files"
        
        # Apply batch size limit to prevent resource exhaustion
        if [[ ${#file_array[@]} -gt $MAX_FILES_PER_BATCH ]]; then
            echo -e "${YELLOW}⚠ Too many files (${#file_array[@]}) in batch for $config_dir, splitting...${NC}"
            local -a batch_files
            local batch_count=0
            for file_path in "${file_array[@]}"; do
                batch_files+=("$file_path")
                ((batch_count++))
                
                if [[ $batch_count -eq $MAX_FILES_PER_BATCH ]]; then
                    # Process this batch
                    process_eslint_batch "$config_dir" "${batch_files[@]}"
                    batch_files=()
                    batch_count=0
                fi
            done
            
            # Process remaining files
            if [[ ${#batch_files[@]} -gt 0 ]]; then
                process_eslint_batch "$config_dir" "${batch_files[@]}"
            fi
        else
            process_eslint_batch "$config_dir" "${file_array[@]}"
        fi
    done
}

# Process a single batch of ESLint files
process_eslint_batch() {
    local config_dir="$1"
    shift
    local -a file_array=("$@")
    
    echo -e "${BLUE}→ Batch checking ${#file_array[@]} files in $config_dir${NC}"
    
    # Check if ESLint is available (use first file for dependency checking)
    if ! eslint_cmd=$(check_eslint_available "$config_dir" "${file_array[0]}"); then
            echo -e "${RED}❌ ESLint not installed in $config_dir${NC}" >&2
            echo -e "${RED}   To fix: cd $config_dir && npm install --save-dev eslint${NC}" >&2
            BLOCKING_ERRORS+=("ESLint not installed. Run: cd $config_dir && npm install --save-dev eslint")
            
            # Store error for JSON
            local session_id="${CLAUDE_SESSION_ID:-unknown}"
            for absolute_path in "${file_array[@]}"; do
                local error_json
                error_json=$(jq -n \
                    --arg file "$absolute_path" \
                    --arg errors "ESLint not installed in $config_dir" \
                    --arg session "$session_id" \
                    '{file_path: $file, errors: $errors, session_id: $session}')
                ERROR_ENTRIES+=("$error_json")
            done
            
            ERRORS_FOUND=true
            return
        fi
        
        # Convert absolute paths to relative paths from config directory
        local -a relative_paths
        for absolute_path in "${file_array[@]}"; do
            local relative_path
            if [[ "$absolute_path" = "$config_dir"/* ]]; then
                relative_path="${absolute_path#"$config_dir"/}"
            else
                relative_path="$absolute_path"
            fi
            relative_paths+=("$relative_path")
        done
        
        # Run ESLint on all files at once with timeout
        local output
        command cd "$config_dir" 2>/dev/null || true
        if output=$(run_with_timeout "$COMMAND_TIMEOUT" "$eslint_cmd" "${relative_paths[@]}"); then
            echo -e "${GREEN}✓ All ${#file_array[@]} files passed linting${NC}"
        else
            echo -e "${YELLOW}⚠ Some files have linting errors, attempting batch auto-fix...${NC}"
            
            # Try to auto-fix the issues with timeout
            if run_with_timeout "$COMMAND_TIMEOUT" "$eslint_cmd" --fix "${relative_paths[@]}" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Auto-fixed some issues${NC}"
                
                # Check again to see if all issues were fixed
                if output=$(run_with_timeout "$COMMAND_TIMEOUT" "$eslint_cmd" "${relative_paths[@]}"); then
                    echo -e "${GREEN}✓ All files now pass linting after auto-fix${NC}"
                else
                    # Some issues remain that couldn't be auto-fixed
                    echo -e "${RED}❌ Some files still have linting errors that cannot be auto-fixed:${NC}" >&2
                    echo "$output" | head -"$MAX_OUTPUT_LINES" >&2
                    if [[ $(echo "$output" | wc -l) -gt $MAX_OUTPUT_LINES ]]; then
                        echo -e "${YELLOW}... (truncated, showing first $MAX_OUTPUT_LINES lines)${NC}" >&2
                    fi
                    
                    # Store error for each file in the batch
                    local session_id="${CLAUDE_SESSION_ID:-unknown}"
                    for absolute_path in "${file_array[@]}"; do
                        local error_json
                        error_json=$(jq -n \
                            --arg file "$absolute_path" \
                            --arg errors "$output" \
                            --arg session "$session_id" \
                            '{file_path: $file, errors: $errors, session_id: $session}')
                        ERROR_ENTRIES+=("$error_json")
                    done
                    
                    BLOCKING_ERRORS+=("${#file_array[@]} files have ESLint errors that must be fixed manually")
                    ERRORS_FOUND=true
                fi
            else
                # Auto-fix failed, show original errors
                echo -e "${RED}❌ Auto-fix failed:${NC}" >&2
                echo "$output" | head -"$MAX_OUTPUT_LINES" >&2
                if [[ $(echo "$output" | wc -l) -gt $MAX_OUTPUT_LINES ]]; then
                    echo -e "${YELLOW}... (truncated, showing first $MAX_OUTPUT_LINES lines)${NC}" >&2
                fi
                
                # Store error for each file in the batch
                local session_id="${CLAUDE_SESSION_ID:-unknown}"
                for absolute_path in "${file_array[@]}"; do
                    local error_json
                    error_json=$(jq -n \
                        --arg file "$absolute_path" \
                        --arg errors "$output" \
                        --arg session "$session_id" \
                        '{file_path: $file, errors: $errors, session_id: $session}')
                    ERROR_ENTRIES+=("$error_json")
                done
                
                BLOCKING_ERRORS+=("${#file_array[@]} files have ESLint errors that must be fixed manually")
                ERRORS_FOUND=true
            fi
        fi
}


# Main execution
echo -e "${YELLOW}🔍 Smart Lint Hook: Checking modified files...${NC}"

# Clear caches from previous runs to ensure reliability
unset ESLINT_CONFIG_CACHE
unset TYPESCRIPT_CONFIG_CACHE
unset TOOL_AVAILABILITY_CACHE
unset ABSOLUTE_PATH_CACHE
unset NUXT_CONFIG_CACHE

# Reinitialize cache arrays
declare -A ESLINT_CONFIG_CACHE
declare -A TYPESCRIPT_CONFIG_CACHE
declare -A TOOL_AVAILABILITY_CACHE
declare -A ABSOLUTE_PATH_CACHE
declare -A NUXT_CONFIG_CACHE

# Early exit optimization: check if any tools are available
TOOLS_AVAILABLE=false
if command -v eslint &> /dev/null || command -v tsc &> /dev/null || command -v vue-tsc &> /dev/null || command -v shellcheck &> /dev/null; then
    TOOLS_AVAILABLE=true
fi

# ============================================================================
# FILE COLLECTION STRATEGY
# ============================================================================
# Three-tier fallback system optimized for different hook events:
#
# Tier 1: Hook stdin JSON (PostToolUse) - IMMEDIATE FEEDBACK
#   - Per-file processing
#   - 100% accurate
#   - Runs on every Edit/Write operation
#   - Provides instant linting feedback
#
# Tier 2: CLAUDE_MODIFIED_FILES (SessionEnd, manual) - BATCH OPTIMIZATION
#   - Multi-file batch processing
#   - Preserves ESLint batch optimization
#   - For end-of-session bulk linting or manual invocation
#
# Tier 3: Time-based search - DEBUGGING FALLBACK
#   - Last resort for testing
#   - Inherently unreliable due to timing/directory issues
# ============================================================================

MODIFIED_FILES=()
FILE_SOURCE="unknown"

# Tier 1: Hook stdin (authoritative for PostToolUse hooks)
if [[ -n "$HOOK_FILE_PATH" ]]; then
    echo -e "${GREEN}📥 Received file from Claude Code hook stdin${NC}"
    echo -e "${BLUE}   Tool: $HOOK_TOOL_NAME | File: $(basename "$HOOK_FILE_PATH")${NC}"
    MODIFIED_FILES+=("$HOOK_FILE_PATH")
    FILE_SOURCE="hook_stdin"
fi

# Tier 2: Environment variable (for batch processing)
if [[ ${#MODIFIED_FILES[@]} -eq 0 && -n "${CLAUDE_MODIFIED_FILES:-}" ]]; then
    echo -e "${YELLOW}📋 Using CLAUDE_MODIFIED_FILES environment variable${NC}"
    IFS=$'\n' read -r -d '' -a MODIFIED_FILES <<< "$CLAUDE_MODIFIED_FILES" || true
    FILE_SOURCE="env_variable"

    if [[ ${#MODIFIED_FILES[@]} -gt 0 ]]; then
        echo -e "${BLUE}   Files to process: ${#MODIFIED_FILES[@]}${NC}"
        echo -e "${GREEN}   ✓ Batch mode enabled - ESLint optimization active${NC}"
    fi
fi

# Tier 3: Time-based fallback (debugging/testing only)
if [[ ${#MODIFIED_FILES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  No hook input or environment variable detected${NC}"
    echo -e "${YELLOW}   Falling back to time-based file search (last 1 minute)${NC}"
    echo -e "${YELLOW}   NOTE: This is unreliable and should not be used in production${NC}"

    while IFS= read -r -d '' file; do
        MODIFIED_FILES+=("$file")
    done < <(find . -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.vue" -o -name "*.mjs" -o -name "*.cjs" -o -name "*.sh" -o -name "*.bash" -o -name "*.zsh" -o -name "Makefile" -o -name "makefile" -o -name "*.mk" \) -mmin -1 -print0 2>/dev/null || true)

    FILE_SOURCE="time_based"

    if [[ ${#MODIFIED_FILES[@]} -gt 0 ]]; then
        echo -e "${BLUE}   Found ${#MODIFIED_FILES[@]} recently modified files${NC}"
    fi
fi

# Filter files by type (excluding .nuxt directory)
JS_TS_VUE_FILES=()
SHELL_FILES=()
MAKEFILE_FILES=()
if [[ ${#MODIFIED_FILES[@]} -gt 0 ]]; then
    for file in "${MODIFIED_FILES[@]}"; do
        # Comprehensive input sanitization
        if ! sanitize_file_path "$file"; then
            echo -e "${YELLOW}⚠ Skipping file with unsafe path: $file${NC}" >&2
            continue
        fi
        
        # Skip files in build/dist directories and other common exclusions
        if [[ "$file" =~ /(\.nuxt|node_modules|dist|build|coverage|\.next|\.cache|\.git)/ ]]; then
            continue
        fi
        
        # Skip files that don't exist or aren't readable
        if [[ ! -f "$file" || ! -r "$file" ]]; then
            continue
        fi
        
        # Check file size to prevent DoS attacks
        file_size_bytes=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        max_size_bytes=$((MAX_FILE_SIZE_MB * 1024 * 1024))
        if [[ $file_size_bytes -gt $max_size_bytes ]]; then
            echo -e "${YELLOW}⚠ Skipping large file (${file_size_bytes} bytes): $file${NC}" >&2
            continue
        fi
        
        if [[ "$file" =~ \.(js|jsx|ts|tsx|vue|mjs|cjs)$ ]]; then
            JS_TS_VUE_FILES+=("$file")
        elif [[ "$file" =~ \.(sh|bash|zsh)$ ]] || is_shell_script "$file"; then
            SHELL_FILES+=("$file")
        elif [[ "$file" =~ (Makefile|makefile|\.mk)$ ]]; then
            MAKEFILE_FILES+=("$file")
        fi
    done
fi

# If no files to check were modified, exit successfully
if [[ ${#JS_TS_VUE_FILES[@]} -eq 0 && ${#SHELL_FILES[@]} -eq 0 && ${#MAKEFILE_FILES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ No JavaScript/TypeScript/Vue/Shell/Makefile files to lint${NC}"
    exit 0
fi

# Early exit if no tools are available and we have files to check
if [[ "$TOOLS_AVAILABLE" == "false" ]]; then
    # Check if we have local tools in any nearby node_modules
    local_tools_found=false
    for file in "${JS_TS_VUE_FILES[@]}"; do
        dir="$(dirname "$file")"
        while [[ "$dir" != "/" ]]; do
            if [[ -f "$dir/node_modules/.bin/eslint" ]] || [[ -f "$dir/node_modules/.bin/tsc" ]] || [[ -f "$dir/node_modules/.bin/vue-tsc" ]]; then
                local_tools_found=true
                break
            fi
            dir="$(dirname "$dir")"
        done
        if [[ "$local_tools_found" == "true" ]]; then
            break
        fi
    done
    
    if [[ "$local_tools_found" == "false" && ${#JS_TS_VUE_FILES[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠ No ESLint or TypeScript tools found globally or locally${NC}"
        echo -e "${YELLOW}  Install tools: npm install -g eslint typescript${NC}"
        echo -e "${YELLOW}  Or locally: npm install --save-dev eslint typescript${NC}"
    fi
    
    if [[ ${#SHELL_FILES[@]} -gt 0 ]] && ! command -v shellcheck &> /dev/null; then
        echo -e "${YELLOW}⚠ ShellCheck not available for shell script checking${NC}"
        echo -e "${YELLOW}  Install: brew install shellcheck (macOS) or apt-get install shellcheck (Ubuntu)${NC}"
    fi
fi

total_files=$((${#JS_TS_VUE_FILES[@]} + ${#SHELL_FILES[@]} + ${#MAKEFILE_FILES[@]}))

# Display session info with processing mode
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Smart Lint Session Info${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  File Source: ${NC}$FILE_SOURCE"
echo -e "${BLUE}  Total Files: ${NC}$total_files"
echo -e "${BLUE}  JS/TS/Vue:   ${NC}${#JS_TS_VUE_FILES[@]}"
echo -e "${BLUE}  Shell:       ${NC}${#SHELL_FILES[@]}"
echo -e "${BLUE}  Makefile:    ${NC}${#MAKEFILE_FILES[@]}"

if [[ "$FILE_SOURCE" == "hook_stdin" ]]; then
    echo -e "${GREEN}  Mode: Per-file (immediate feedback)${NC}"
elif [[ "$FILE_SOURCE" == "env_variable" ]]; then
    echo -e "${GREEN}  Mode: Batch (performance optimized)${NC}"
else
    echo -e "${YELLOW}  Mode: Fallback (debugging)${NC}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Phase 1: Makefile Check
if [[ ${#MAKEFILE_FILES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}=== Makefile Phase ===${NC}"
    for file in "${MAKEFILE_FILES[@]}"; do
        check_makefile "$file" || true
    done
    echo ""
fi

# Phase 2: ShellCheck
if [[ ${#SHELL_FILES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}=== ShellCheck Phase ===${NC}"
    for file in "${SHELL_FILES[@]}"; do
        check_shell_script "$file" || true
    done
    echo ""
fi

# Phase 3: ESLint (Batch Processing)
if [[ ${#JS_TS_VUE_FILES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}=== ESLint Phase ===${NC}"
    lint_files_batch "${JS_TS_VUE_FILES[@]}"
    echo ""
fi

# ============================================================================
# TYPESCRIPT BATCH OPTIMIZATION
# ============================================================================

# Function to batch TypeScript checking by shared tsconfig
check_typescript_batch() {
    local -a files=("$@")
    local -A files_by_tsconfig

    # Group files by their tsconfig directory
    for file in "${files[@]}"; do
        local absolute_path
        absolute_path="$(get_absolute_path "$file")"

        if config_dir=$(find_tsconfig "$absolute_path"); then
            # Add file to group for this tsconfig
            if [[ -n "${files_by_tsconfig[$config_dir]:-}" ]]; then
                files_by_tsconfig[$config_dir]+=" $absolute_path"
            else
                files_by_tsconfig[$config_dir]="$absolute_path"
            fi
        else
            # No tsconfig, check individually
            check_typescript "$file" || true
        fi
    done

    # Process each tsconfig group in batch
    for config_dir in "${!files_by_tsconfig[@]}"; do
        local config_files="${files_by_tsconfig[$config_dir]}"
        local -a file_array
        read -ra file_array <<< "$config_files"

        # Only batch if we have multiple files
        if [[ ${#file_array[@]} -gt 1 ]]; then
            process_typescript_batch "$config_dir" "${file_array[@]}"
        else
            # Single file, use existing per-file logic
            check_typescript "${file_array[0]}" || true
        fi
    done
}

# Process TypeScript batch for files sharing same tsconfig
process_typescript_batch() {
    local config_dir="$1"
    shift
    local -a file_array=("$@")

    echo -e "${BLUE}→ Batch type checking ${#file_array[@]} files with $config_dir/tsconfig.json${NC}"

    # Determine if we need vue-tsc (if any file is .vue)
    local needs_vue_tsc=false
    for file in "${file_array[@]}"; do
        if [[ "$file" =~ \.vue$ ]]; then
            needs_vue_tsc=true
            break
        fi
    done

    # Get appropriate TypeScript compiler
    local tsc_cmd
    if [[ "$needs_vue_tsc" == "true" ]]; then
        if ! tsc_cmd=$(check_typescript_available "$config_dir" "true" "${file_array[0]}"); then
            echo -e "${YELLOW}⚠ vue-tsc not available, falling back to per-file checking${NC}"
            for file in "${file_array[@]}"; do
                check_typescript "$file" || true
            done
            return
        fi
    else
        if ! tsc_cmd=$(check_typescript_available "$config_dir" "false" "${file_array[0]}"); then
            echo -e "${YELLOW}⚠ tsc not available, falling back to per-file checking${NC}"
            for file in "${file_array[@]}"; do
                check_typescript "$file" || true
            done
            return
        fi
    fi

    # Convert to relative paths from config directory
    local -a relative_paths
    for absolute_path in "${file_array[@]}"; do
        local relative_path
        if [[ "$absolute_path" = "$config_dir"/* ]]; then
            relative_path="${absolute_path#"$config_dir"/}"
        else
            relative_path="$absolute_path"
        fi
        relative_paths+=("$relative_path")
    done

    # Run TypeScript on all files at once
    local output
    command cd "$config_dir" 2>/dev/null || true
    if output=$(run_with_timeout "$COMMAND_TIMEOUT" "$tsc_cmd" --noEmit "${relative_paths[@]}" 2>&1); then
        echo -e "${GREEN}✓ All ${#file_array[@]} files passed type checking${NC}"
    else
        echo -e "${RED}❌ Type errors found in batch:${NC}" >&2
        echo "$output" | head -40 >&2

        # Store errors
        local session_id="${CLAUDE_SESSION_ID:-unknown}"
        for absolute_path in "${file_array[@]}"; do
            local error_json
            error_json=$(jq -n \
                --arg file "$absolute_path" \
                --arg errors "$output" \
                --arg session "$session_id" \
                '{file_path: $file, errors: $errors, session_id: $session}')
            ERROR_ENTRIES+=("$error_json")
        done

        BLOCKING_ERRORS+=("${#file_array[@]} files have TypeScript type errors")
        ERRORS_FOUND=true
    fi
}

# Phase 4: TypeScript Type Checking (batch optimized)
if [[ ${#JS_TS_VUE_FILES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}=== TypeScript Phase ===${NC}"
    TS_VUE_FILES=()
    for file in "${JS_TS_VUE_FILES[@]}"; do
        if [[ "$file" =~ \.(ts|tsx|vue)$ ]]; then
            TS_VUE_FILES+=("$file")
        fi
    done

    if [[ ${#TS_VUE_FILES[@]} -gt 0 ]]; then
        # Use batch processing if multiple files (optimization)
        if [[ "$FILE_SOURCE" == "hook_stdin" || ${#TS_VUE_FILES[@]} -eq 1 ]]; then
            # Single file or per-file mode: use existing logic
            for file in "${TS_VUE_FILES[@]}"; do
                check_typescript "$file" || true
            done
        else
            # Batch mode: use optimized batch processing
            echo -e "${GREEN}✓ Batch TypeScript mode enabled${NC}"
            check_typescript_batch "${TS_VUE_FILES[@]}"
        fi
    else
        echo -e "${GREEN}No TypeScript or Vue files to type check${NC}"
    fi
fi

# Update eslint_errors.json if there were errors
if [[ "$ERRORS_FOUND" == "true" ]]; then
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$LINT_ERRORS_FILE")"
    
    # Create or update the errors file
    if [[ -f "$LINT_ERRORS_FILE" ]]; then
        # Read existing errors
        existing_errors=$(cat "$LINT_ERRORS_FILE" 2>/dev/null || echo "[]")
    else
        existing_errors="[]"
    fi
    
    # Combine all error entries into a JSON array
    if [[ ${#ERROR_ENTRIES[@]} -gt 0 ]]; then
        new_errors="["
        for i in "${!ERROR_ENTRIES[@]}"; do
            if [[ $i -gt 0 ]]; then
                new_errors+=","
            fi
            new_errors+="${ERROR_ENTRIES[$i]}"
        done
        new_errors+="]"
        
        # Merge with existing errors (keep last 100 entries)
        merged_errors=$(echo "$existing_errors" | jq ". + $new_errors | .[-100:]" 2>/dev/null || echo "$new_errors")
        echo "$merged_errors" > "$LINT_ERRORS_FILE"
    fi
    
    echo ""
    echo -e "${RED}⛔ BLOCKING: Found ${#BLOCKING_ERRORS[@]} error(s) that must be fixed:${NC}" >&2
    for error in "${BLOCKING_ERRORS[@]}"; do
        echo -e "${RED}   • $error${NC}" >&2
    done
    echo ""
    echo -e "${RED}👉 ACTION REQUIRED: Fix the ESLint errors above before continuing.${NC}" >&2
    echo -e "${YELLOW}💡 The hook already tried auto-fix. Remaining errors need manual fixes.${NC}" >&2
    echo -e "${YELLOW}💡 Common fixes:${NC}" >&2
    echo -e "${YELLOW}   - Remove unused variables${NC}" >&2
    echo -e "${YELLOW}   - Add missing semicolons${NC}" >&2
    echo -e "${YELLOW}   - Fix type errors${NC}" >&2
    echo ""
    echo -e "${BLUE}📝 Please edit the file(s) to fix these errors, then try again.${NC}" >&2
    
    # Exit with code 2 to indicate blocking errors
    exit 2
fi

echo ""
echo -e "${GREEN}✅ All files passed linting and type checking! Continue with your task.${NC}"
exit 0