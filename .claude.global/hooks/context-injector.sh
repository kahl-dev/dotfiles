#!/usr/bin/env bash

echo "$(date): Context injector triggered" >> /tmp/claude-hook-debug.log

get_project_context() {
    local context=""
    
    if [[ -f "package.json" ]]; then
        local project_name=$(jq -r '.name // "unknown"' package.json 2>/dev/null)
        local project_type=$(jq -r '.type // "commonjs"' package.json 2>/dev/null)
        context+="📦 Node.js project: $project_name ($project_type)\n"
        
        if jq -e '.dependencies.vue' package.json >/dev/null 2>&1; then
            context+="🔷 Vue.js framework detected\n"
        fi
        if jq -e '.dependencies.react' package.json >/dev/null 2>&1; then
            context+="⚛️ React framework detected\n"
        fi
        if jq -e '.dependencies.nuxt' package.json >/dev/null 2>&1; then
            context+="💚 Nuxt.js framework detected\n"
        fi
        
        local scripts=$(jq -r '.scripts | keys[]' package.json 2>/dev/null | head -5 | tr '\n' ' ')
        if [[ -n "$scripts" ]]; then
            context+="🔧 Available scripts: $scripts\n"
        fi
    fi
    
    if [[ -f "Cargo.toml" ]]; then
        local project_name=$(grep '^name =' Cargo.toml | cut -d'"' -f2 2>/dev/null)
        context+="🦀 Rust project: $project_name\n"
    fi
    
    if [[ -f "pyproject.toml" ]]; then
        local project_name=$(grep '^name =' pyproject.toml | cut -d'"' -f2 2>/dev/null)
        context+="🐍 Python project: $project_name\n"
    fi
    
    if [[ -f "go.mod" ]]; then
        local module_name=$(head -1 go.mod | cut -d' ' -f2 2>/dev/null)
        context+="🔷 Go module: $module_name\n"
    fi
    
    if [[ -d ".git" ]]; then
        local branch=$(git branch --show-current 2>/dev/null)
        local status=$(git status --porcelain 2>/dev/null | wc -l)
        if [[ -n "$branch" ]]; then
            context+="🌿 Git branch: $branch"
            if [[ "$status" -gt 0 ]]; then
                context+=" ($status changes)"
            fi
            context+="\n"
        fi
    fi
    
    local recent_files=$(find . -maxdepth 2 -type f \
        \( -name "*.js" -o -name "*.ts" -o -name "*.vue" -o -name "*.py" -o -name "*.rs" \) \
        -mtime -1 2>/dev/null | head -3 | sed 's|^\./||' | tr '\n' ' ')
    if [[ -n "$recent_files" ]]; then
        context+="📝 Recently modified: $recent_files\n"
    fi
    
    echo -e "$context"
}

check_context_files() {
    local context=""
    
    if [[ -f ".claude-context" ]]; then
        context+="📋 Project context:\n$(cat .claude-context)\n\n"
    fi
    
    if [[ -f "README.md" ]]; then
        local readme_excerpt=$(head -5 README.md | grep -v '^#' | grep -v '^$' | head -2)
        if [[ -n "$readme_excerpt" ]]; then
            context+="📖 README excerpt: $readme_excerpt\n"
        fi
    fi
    
    echo -e "$context"
}

PROJECT_CONTEXT=$(get_project_context)
CONTEXT_FILES=$(check_context_files)

if [[ -n "$PROJECT_CONTEXT" ]] || [[ -n "$CONTEXT_FILES" ]]; then
    echo "💡 CONTEXT INJECTION:"
    echo "===================="
    
    if [[ -n "$CONTEXT_FILES" ]]; then
        echo -e "$CONTEXT_FILES"
    fi
    
    if [[ -n "$PROJECT_CONTEXT" ]]; then
        echo -e "$PROJECT_CONTEXT"
    fi
    
    echo "===================="
    echo ""
fi

exit 0