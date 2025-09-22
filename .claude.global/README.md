# Claude Global Configuration

This directory contains the comprehensive global configuration system for Claude Code, providing centralized instructions, commands, and automation across all projects.

## 📁 Directory Structure

```
.claude.global/
├── GLOBAL.CLAUDE.md       # Main global configuration with @includes
├── settings.json          # Claude settings, permissions, and hooks
├── commands/              # Custom slash commands
│   ├── analyze.md         # /analyze - Comprehensive codebase analysis
│   ├── claude/            # Claude-specific development tools
│   │   └── prompt.md      # /claude/prompt - Prompt engineering expert
│   ├── commit.md          # /commit - Create conventional commits
│   └── user/review/       # /user:review:* - Review workflow commands
├── instructions/          # Modular instruction files
│   ├── build-commands.md  # Build and verification guidelines
│   ├── code-principles.md # Core coding principles
│   ├── code-style.md      # Human-readable code style rules
│   ├── constraints.md     # Essential development constraints
│   ├── conversation.md    # Communication style guidelines
│   ├── efficiency.md      # Development efficiency patterns
│   ├── hook-errors.md     # Hook error handling protocols
│   ├── llm-code-style.md  # LLM-specific code patterns
│   ├── llm-context.md     # Context management (.llm/ directory)
│   ├── llm-git-commits.md # Git commit conventions
│   ├── mcp-integration.md # MCP server usage patterns
│   ├── problem-solving.md # Problem-solving methodologies
│   ├── security.md        # Security and safety guidelines
│   ├── tests.md           # Testing guidelines
│   ├── tool-use.md        # Tool usage patterns and priorities
│   └── workflow.md        # Core development workflow
├── hooks/                 # Automation and validation hooks
└── shared/               # Shared resources and utilities

```

## 🔧 Key Features

### Comprehensive System Knowledge
The `GLOBAL.CLAUDE.md` file includes extensive documentation for:
- **Hooks System**: Development best practices, security guidelines, debugging tools
- **Slash Commands**: Command development, security patterns, testing approaches
- **Settings Configuration**: Precedence rules, key options, integration patterns
- **MCP Integration**: Context7, GitHub/GitLab, Playwright, Figma, Cloudinary usage

### Modular Instructions
The configuration uses `@instructions/filename.md` syntax for modular organization:
- **Core Workflow**: Research → Plan → Implement → Validate methodology
- **Essential Constraints**: Security-first development boundaries
- **Code Principles**: Architecture, quality, and maintainability guidelines
- **Communication**: Concise, direct interaction patterns

### Expert Command Suite
Slash commands provide specialized capabilities:
- **`/analyze`**: Senior architect-level codebase analysis with actionable insights
- **`/claude/prompt`**: Expert prompt engineering for custom command development
- **`/user:review:hard`**: Strict production readiness gate (blocking)
- **`/user:review:simple`**: Advisory follow-up analysis (post-gate)
- **`/commit`**: Conventional commit message generation

### Development Integration
- **Context7 Priority**: Always check latest documentation before implementation
- **Parallel Operations**: Batch tool calls for optimal performance  
- **Security Hardening**: Input validation, credential protection, safe defaults
- **Hook Error Handling**: Immediate resolution protocol for blocking issues

## 🚀 Usage

1. **Global Configuration**: Symlinked to `~/.claude/` for consistent behavior across all projects
2. **Dotbot Integration**: Managed through dotfiles repository for version control
3. **Project Overrides**: Individual projects can extend with local `.claude/CLAUDE.md`
4. **Command Access**: Type `/` followed by command name in Claude Code sessions

### Expert Commands
- **`/analyze`**: Comprehensive codebase analysis with architectural insights
- **`/claude/prompt`**: Expert prompt engineering and command development
- **`/user:review:hard`**: Production readiness gate (must pass before committing)
- **`/user:review:simple`**: Deep follow-up review for insights/tech debt
- **`/commit`**: Conventional commit message generation with proper formatting

## 📝 Maintenance

### Adding New Instructions
1. Create a new `.md` file in `instructions/`
2. Add the reference in `GLOBAL.CLAUDE.md` using `@instructions/newfile.md`
3. Follow modular organization principles

### Creating New Commands
1. Add a new `.md` file in `commands/` (use subdirectories for organization)
2. Include frontmatter with description: `description: "Command purpose"`
3. Use expert-level prompt engineering techniques
4. Follow security guidelines (no shell injection, input validation)

### System Evolution
1. **Context7 Integration**: Always fetch latest docs before major changes
2. **Security Review**: Validate all new hooks and commands for safety
3. **Performance Optimization**: Batch operations and use specialized tools
4. **Documentation Sync**: Keep README aligned with actual file structure

## 🔐 Security Framework

### Core Security Principles
- **Input Validation**: All user inputs sanitized and validated
- **Path Security**: Absolute paths required, traversal attack prevention
- **Credential Protection**: Environment variables only, no hardcoded secrets
- **Command Safety**: Dangerous operations explicitly blocked
- **Hook Validation**: Timeout limits, proper error handling, shell injection prevention

### Security Checklist for New Commands
- [ ] Input validation implemented
- [ ] No hardcoded secrets or credentials
- [ ] Appropriate error handling with timeouts
- [ ] Permissions verified and documented
- [ ] Shell injection prevention measures
- [ ] Testing with malicious inputs completed

## 📚 Architecture Overview

This global configuration system provides a foundation for consistent, secure, and efficient Claude Code usage across all development projects. It emphasizes:

- **Research-Driven Development**: Context7 integration for up-to-date documentation
- **Security-First Approach**: Multiple layers of protection and validation
- **Expert-Level Tooling**: Sophisticated analysis and development capabilities
- **Modular Organization**: Easy maintenance and evolution
- **Version Control Integration**: Full dotfiles repository management

The system is designed to scale from individual developer productivity to team-wide standardization while maintaining flexibility for project-specific needs.
