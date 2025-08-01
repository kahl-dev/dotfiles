#!/bin/bash

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
        "PATH=${fnm_path}/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/bin:/bin"
        "HOME=$HOME"
        "USER=${USER:-unknown}"
        "LANG=${LANG:-C}"
        "LC_ALL=C"
        "FNM_MULTISHELL_PATH=${FNM_MULTISHELL_PATH:-}"
        "FNM_DIR=${FNM_DIR:-}"
    )
    
    # Properly escape all command arguments to prevent injection
    local -a escaped_cmd=()
    for arg in "${cmd[@]}"; do
        escaped_cmd+=("$(printf '%q' "$arg")")
    done
    
    # Use timeout command with restricted environment if available
    if command -v timeout >/dev/null 2>&1; then
        env -i "${env_vars[@]}" timeout "$timeout_seconds" bash -c "${escaped_cmd[*]}" 2>&1
    else
        # Fallback for systems without timeout command
        env -i "${env_vars[@]}" bash -c "${escaped_cmd[*]}" 2>&1
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
    
    # Check for local eslint
    if [[ -f "$dir/node_modules/.bin/eslint" ]]; then
        TOOL_AVAILABILITY_CACHE[$cache_key]="$dir/node_modules/.bin/eslint"
        echo "$dir/node_modules/.bin/eslint"
        return 0
    fi
    
    # Check for global eslint
    if command -v eslint &> /dev/null; then
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

# Function to check if TypeScript compiler is available with caching
check_typescript_available() {
    local dir="$1"
    local is_vue_file="$2"
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
    
    # For Vue files, prefer vue-tsc
    if [[ "$is_vue_file" == "true" ]]; then
        # Check for local vue-tsc
        if [[ -f "$dir/node_modules/.bin/vue-tsc" ]]; then
            TOOL_AVAILABILITY_CACHE[$cache_key]="$dir/node_modules/.bin/vue-tsc"
            echo "$dir/node_modules/.bin/vue-tsc"
            return 0
        fi
        
        # Check for global vue-tsc
        if command -v vue-tsc &> /dev/null; then
            TOOL_AVAILABILITY_CACHE[$cache_key]="vue-tsc"
            echo "vue-tsc"
            return 0
        fi
    fi
    
    # Check for local tsc
    if [[ -f "$dir/node_modules/.bin/tsc" ]]; then
        TOOL_AVAILABILITY_CACHE[$cache_key]="$dir/node_modules/.bin/tsc"
        echo "$dir/node_modules/.bin/tsc"
        return 0
    fi
    
    # Check for global tsc
    if command -v tsc &> /dev/null; then
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
    if output=$(cd "$temp_dir" && run_with_timeout "$COMMAND_TIMEOUT" make -n); then
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
    if [[ "$file_path" =~ \.(sh|bash|zsh)$ ]]; then
        is_valid_shell_script=true
    elif is_shell_script "$absolute_path"; then
        is_valid_shell_script=true
    fi
    
    if [[ "$is_valid_shell_script" != "true" ]]; then
        echo -e "${YELLOW}⚠ $file_name does not appear to be a shell script, skipping${NC}"
        return 0
    fi
    
    # Run ShellCheck with timeout and secure execution
    local output
    
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
    
    echo -e "${BLUE}→ Type checking $file_name${NC}"
    
    # Find the nearest tsconfig.json
    if ! config_dir=$(find_tsconfig "$absolute_path"); then
        echo -e "${YELLOW}⚠ No tsconfig.json found for $file_path${NC}"
        echo -e "${YELLOW}  TypeScript type checking skipped${NC}"
        return 0
    fi
    
    # Check if TypeScript compiler is available
    if ! tsc_cmd=$(check_typescript_available "$config_dir" "$is_vue_file"); then
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
    
    # Change to the config directory
    cd "$config_dir" 2>/dev/null || true
    
    # Run tsc with --noEmit to only check types
    if output=$("$tsc_cmd" --noEmit "$absolute_path" 2>&1); then
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
    
    # Check if ESLint is available
    if ! eslint_cmd=$(check_eslint_available "$config_dir"); then
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
        cd "$config_dir" 2>/dev/null || true
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

# Reinitialize cache arrays
declare -A ESLINT_CONFIG_CACHE
declare -A TYPESCRIPT_CONFIG_CACHE
declare -A TOOL_AVAILABILITY_CACHE
declare -A ABSOLUTE_PATH_CACHE

# Early exit optimization: check if any tools are available
TOOLS_AVAILABLE=false
if command -v eslint &> /dev/null || command -v tsc &> /dev/null || command -v vue-tsc &> /dev/null || command -v shellcheck &> /dev/null; then
    TOOLS_AVAILABLE=true
fi

# Get list of modified files from environment or git
MODIFIED_FILES=()

# Check if we have CLAUDE_MODIFIED_FILES environment variable
if [[ -n "${CLAUDE_MODIFIED_FILES:-}" ]]; then
    IFS=$'\n' read -r -d '' -a MODIFIED_FILES <<< "$CLAUDE_MODIFIED_FILES" || true
else
    # Fallback: check current directory for recently modified files
    while IFS= read -r -d '' file; do
        MODIFIED_FILES+=("$file")
    done < <(find . -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.vue" -o -name "*.mjs" -o -name "*.cjs" -o -name "*.sh" -o -name "*.bash" -o -name "*.zsh" -o -name "Makefile" -o -name "makefile" -o -name "*.mk" \) -mmin -1 -print0 2>/dev/null || true)
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
echo -e "${BLUE}Found $total_files file(s) to check: ${#JS_TS_VUE_FILES[@]} JS/TS/Vue, ${#SHELL_FILES[@]} Shell, ${#MAKEFILE_FILES[@]} Makefile${NC}"
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

# Phase 4: TypeScript Type Checking (only for TS and Vue files)
if [[ ${#JS_TS_VUE_FILES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}=== TypeScript Phase ===${NC}"
    TS_VUE_FILES=()
    for file in "${JS_TS_VUE_FILES[@]}"; do
        if [[ "$file" =~ \.(ts|tsx|vue)$ ]]; then
            TS_VUE_FILES+=("$file")
        fi
    done

    if [[ ${#TS_VUE_FILES[@]} -gt 0 ]]; then
        for file in "${TS_VUE_FILES[@]}"; do
            check_typescript "$file" || true
        done
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