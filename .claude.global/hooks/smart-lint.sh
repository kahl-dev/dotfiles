#!/bin/bash

# Smart Lint Hook for JavaScript, TypeScript, and Vue files
# This hook runs ESLint on modified files and provides clear feedback to Claude

# Don't use strict error handling - we want to capture and report errors
set -u

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# File to store eslint errors
ESLINT_ERRORS_FILE="$HOME/.claude.store/user-level/eslint_errors.json"

# Initialize error tracking
ERRORS_FOUND=false
ERROR_ENTRIES=()
BLOCKING_ERRORS=()

# Function to find the nearest ESLint config
find_eslint_config() {
    local file_path="$1"
    local dir="$(dirname "$file_path")"
    
    # Skip if file is in .nuxt directory
    if [[ "$file_path" =~ /\.nuxt/ ]]; then
        return 1
    fi
    
    while [[ "$dir" != "/" ]]; do
        # Skip if we've reached a .nuxt directory
        if [[ "$(basename "$dir")" == ".nuxt" ]]; then
            return 1
        fi
        
        # Check for various ESLint config files
        for config in ".eslintrc.js" ".eslintrc.cjs" ".eslintrc.json" ".eslintrc.yml" ".eslintrc.yaml" ".eslintrc" "eslint.config.js" "eslint.config.mjs" "eslint.config.cjs"; do
            if [[ -f "$dir/$config" ]]; then
                echo "$dir"
                return 0
            fi
        done
        
        # Check for eslint config in package.json
        if [[ -f "$dir/package.json" ]] && grep -q '"eslintConfig"' "$dir/package.json" 2>/dev/null; then
            echo "$dir"
            return 0
        fi
        
        dir="$(dirname "$dir")"
    done
    
    return 1
}

# Function to check if ESLint is available in a directory
check_eslint_available() {
    local dir="$1"
    
    # Check for local eslint
    if [[ -f "$dir/node_modules/.bin/eslint" ]]; then
        echo "$dir/node_modules/.bin/eslint"
        return 0
    fi
    
    # Check for global eslint
    if command -v eslint &> /dev/null; then
        echo "eslint"
        return 0
    fi
    
    return 1
}

# Function to find the nearest tsconfig.json
find_tsconfig() {
    local file_path="$1"
    local dir="$(dirname "$file_path")"
    
    # Skip if file is in .nuxt directory
    if [[ "$file_path" =~ /\.nuxt/ ]]; then
        return 1
    fi
    
    while [[ "$dir" != "/" ]]; do
        # Skip if we've reached a .nuxt directory
        if [[ "$(basename "$dir")" == ".nuxt" ]]; then
            return 1
        fi
        
        if [[ -f "$dir/tsconfig.json" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    
    return 1
}

# Function to check if TypeScript compiler is available
check_typescript_available() {
    local dir="$1"
    local is_vue_file="$2"
    
    # For Vue files, prefer vue-tsc
    if [[ "$is_vue_file" == "true" ]]; then
        # Check for local vue-tsc
        if [[ -f "$dir/node_modules/.bin/vue-tsc" ]]; then
            echo "$dir/node_modules/.bin/vue-tsc"
            return 0
        fi
        
        # Check for global vue-tsc
        if command -v vue-tsc &> /dev/null; then
            echo "vue-tsc"
            return 0
        fi
    fi
    
    # Check for local tsc
    if [[ -f "$dir/node_modules/.bin/tsc" ]]; then
        echo "$dir/node_modules/.bin/tsc"
        return 0
    fi
    
    # Check for global tsc
    if command -v tsc &> /dev/null; then
        echo "tsc"
        return 0
    fi
    
    return 1
}

# Function to run TypeScript type checking on a file
check_typescript() {
    local file_path="$1"
    local file_name="$(basename "$file_path")"
    local is_vue_file="false"
    
    # Check if it's a Vue file
    if [[ "$file_path" =~ \.vue$ ]]; then
        is_vue_file="true"
    fi
    
    # Get absolute path
    local absolute_path
    if [[ "$file_path" = /* ]]; then
        absolute_path="$file_path"
    else
        absolute_path="$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)/$(basename "$file_path")" || absolute_path="$file_path"
    fi
    
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
    local exit_code
    
    # Change to the config directory
    cd "$config_dir" 2>/dev/null || true
    
    # Run tsc with --noEmit to only check types
    if output=$("$tsc_cmd" --noEmit "$absolute_path" 2>&1); then
        echo -e "${GREEN}✓ $file_name passed type checking${NC}"
        return 0
    else
        exit_code=$?
        echo -e "${RED}❌ $file_name has type errors:${NC}" >&2
        
        # Show first 20 lines of output
        echo "$output" | head -20 >&2
        if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
            echo -e "${YELLOW}... (truncated, showing first 20 lines)${NC}" >&2
        fi
        
        # Store error for JSON output
        local session_id="${CLAUDE_SESSION_ID:-unknown}"
        local error_json=$(jq -n \
            --arg file "$absolute_path" \
            --arg errors "TypeScript: $output" \
            --arg session "$session_id" \
            '{file_path: $file, errors: $errors, session_id: $session}')
        ERROR_ENTRIES+=("$error_json")
        
        BLOCKING_ERRORS+=("$file_name has TypeScript type errors")
        ERRORS_FOUND=true
        return 1
    fi
}

# Function to run ESLint on a file
lint_file() {
    local file_path="$1"
    local file_name="$(basename "$file_path")"
    
    # Get absolute path
    local absolute_path
    if [[ "$file_path" = /* ]]; then
        absolute_path="$file_path"
    else
        absolute_path="$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)/$(basename "$file_path")" || absolute_path="$file_path"
    fi
    
    echo -e "${BLUE}→ Checking $file_name${NC}"
    
    # Find the nearest ESLint config
    if ! config_dir=$(find_eslint_config "$absolute_path"); then
        echo -e "${YELLOW}⚠ No ESLint config found for $file_path${NC}"
        echo -e "${YELLOW}  Consider adding .eslintrc.js or eslint.config.js to your project${NC}"
        return 0
    fi
    
    # Check if ESLint is available
    if ! eslint_cmd=$(check_eslint_available "$config_dir"); then
        echo -e "${RED}❌ ESLint not installed in $config_dir${NC}" >&2
        echo -e "${RED}   To fix: cd $config_dir && npm install --save-dev eslint${NC}" >&2
        BLOCKING_ERRORS+=("ESLint not installed. Run: cd $config_dir && npm install --save-dev eslint")
        
        # Store error for JSON
        local session_id="${CLAUDE_SESSION_ID:-unknown}"
        local error_json=$(jq -n \
            --arg file "$absolute_path" \
            --arg errors "ESLint not installed in $config_dir" \
            --arg session "$session_id" \
            '{file_path: $file, errors: $errors, session_id: $session}')
        ERROR_ENTRIES+=("$error_json")
        
        ERRORS_FOUND=true
        return 1
    fi
    
    # Run ESLint
    local output
    local exit_code
    local relative_path
    
    # Convert absolute path to relative from config directory (project root)
    if [[ "$absolute_path" = "$config_dir"/* ]]; then
        relative_path="${absolute_path#$config_dir/}"
    else
        relative_path="$absolute_path"
    fi
    
    # Run ESLint from the project root with relative path
    cd "$config_dir" 2>/dev/null || true
    if output=$("$eslint_cmd" "$relative_path" 2>&1); then
        echo -e "${GREEN}✓ $file_name passed linting${NC}"
        return 0
    else
        exit_code=$?
        echo -e "${YELLOW}⚠ $file_name has linting errors, attempting auto-fix...${NC}"
        
        # Try to auto-fix the issues
        local fix_output
        if fix_output=$("$eslint_cmd" --fix "$relative_path" 2>&1); then
            echo -e "${GREEN}✅ Auto-fixed some issues in $file_name${NC}"
            
            # Check again to see if all issues were fixed
            if output=$("$eslint_cmd" "$relative_path" 2>&1); then
                echo -e "${GREEN}✓ $file_name now passes linting after auto-fix${NC}"
                return 0
            else
                # Some issues remain that couldn't be auto-fixed
                echo -e "${RED}❌ $file_name still has linting errors that cannot be auto-fixed:${NC}" >&2
                echo "$output" | head -20 >&2
                if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
                    echo -e "${YELLOW}... (truncated, showing first 20 lines)${NC}" >&2
                fi
            fi
        else
            # Auto-fix failed, show original errors
            echo -e "${RED}❌ Auto-fix failed for $file_name:${NC}" >&2
            echo "$output" | head -20 >&2
            if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
                echo -e "${YELLOW}... (truncated, showing first 20 lines)${NC}" >&2
            fi
        fi
        
        # Store error for JSON output
        local session_id="${CLAUDE_SESSION_ID:-unknown}"
        local error_json=$(jq -n \
            --arg file "$absolute_path" \
            --arg errors "$output" \
            --arg session "$session_id" \
            '{file_path: $file, errors: $errors, session_id: $session}')
        ERROR_ENTRIES+=("$error_json")
        
        BLOCKING_ERRORS+=("$file_name has ESLint errors that must be fixed manually")
        ERRORS_FOUND=true
        return 1
    fi
}

# Main execution
echo -e "${YELLOW}🔍 Smart Lint Hook: Checking modified files...${NC}"

# Get list of modified files from environment or git
MODIFIED_FILES=()

# Check if we have CLAUDE_MODIFIED_FILES environment variable
if [[ -n "${CLAUDE_MODIFIED_FILES:-}" ]]; then
    IFS=$'\n' read -r -d '' -a MODIFIED_FILES <<< "$CLAUDE_MODIFIED_FILES" || true
else
    # Fallback: check current directory for recently modified files
    while IFS= read -r -d '' file; do
        MODIFIED_FILES+=("$file")
    done < <(find . -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.vue" -o -name "*.mjs" -o -name "*.cjs" \) -mmin -1 -print0 2>/dev/null || true)
fi

# Filter for JS/TS/Vue files (excluding .nuxt directory)
JS_TS_VUE_FILES=()
if [[ ${#MODIFIED_FILES[@]} -gt 0 ]]; then
    for file in "${MODIFIED_FILES[@]}"; do
        # Skip files in .nuxt directory
        if [[ "$file" =~ /\.nuxt/ ]]; then
            continue
        fi
        
        if [[ "$file" =~ \.(js|jsx|ts|tsx|vue|mjs|cjs)$ ]]; then
            JS_TS_VUE_FILES+=("$file")
        fi
    done
fi

# If no JS/TS/Vue files were modified, exit successfully
if [[ ${#JS_TS_VUE_FILES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ No JavaScript/TypeScript/Vue files to lint${NC}"
    exit 0
fi

echo -e "${BLUE}Found ${#JS_TS_VUE_FILES[@]} file(s) to check${NC}"
echo ""

# Phase 1: ESLint
echo -e "${YELLOW}=== ESLint Phase ===${NC}"
for file in "${JS_TS_VUE_FILES[@]}"; do
    lint_file "$file" || true
done

# Phase 2: TypeScript Type Checking (only for TS and Vue files)
echo ""
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

# Update eslint_errors.json if there were errors
if [[ "$ERRORS_FOUND" == "true" ]]; then
    # Create or update the errors file
    if [[ -f "$ESLINT_ERRORS_FILE" ]]; then
        # Read existing errors
        existing_errors=$(cat "$ESLINT_ERRORS_FILE" 2>/dev/null || echo "[]")
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
        echo "$merged_errors" > "$ESLINT_ERRORS_FILE"
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