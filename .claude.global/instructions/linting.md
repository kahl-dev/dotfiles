# 🧹 Code Quality & Linting System

## ESLint Configuration

**Primary Config**: `eslint.config.mjs` - Uses Anthony Fu's config with Nuxt integration
**Features**:
- TypeScript support with `@typescript-eslint`
- Vue.js component linting
- Auto-import detection
- Unused imports removal
- Consistent code style enforcement

**Ignored Patterns**:
- Documentation files (`**/*.md`)
- `.ignore` suffixed files
- `.nuxt/` generated files

## TypeScript Type Checking

**Tools**: `vue-tsc` for Vue components + TypeScript
**Config**: `tsconfig.json` extends Nuxt's generated config
**Strict Mode**: Enabled for better type safety

## Available Commands

### Package.json Scripts
```bash
# Linting
yarn lint                # Run ESLint on entire project
yarn lint:fix            # Auto-fix ESLint issues
yarn lint:ts             # TypeScript + ESLint combined
yarn lint:staged         # Lint only staged files
yarn lint:changed        # Lint only changed files vs HEAD

# Type Checking  
yarn typecheck           # Run TypeScript type checking
yarn typecheck:watch     # Watch mode for type checking
```

### Makefile Commands
```bash
# Quality Control (Recommended)
make quality             # Full quality check (lint + typecheck + test)
make lint                # Run ESLint
make lint-fix            # Auto-fix issues
make typecheck           # TypeScript checking
make lint-staged         # Pre-commit linting
make lint-changed        # Git diff linting
```

## Pre-commit Hook System

**Tool**: Husky + lint-staged
**Config**: `lint-staged.config.js`
**Trigger**: Every `git commit`

**What Happens**:
1. `git commit` triggered
2. Husky runs `.husky/pre-commit`
3. lint-staged processes staged files
4. ESLint + vue-tsc run on changed files only
5. Commit proceeds only if all checks pass

## Lint-staged Configuration

**File**: `lint-staged.config.js`
```javascript
{
  '*.{js,jsx,json}': ['eslint --fix'],
  '*.{ts,tsx}': ['eslint --fix'],
  '*.vue': ['eslint --fix', 'vue-tsc --noEmit']
}
```

**Performance**: Only processes changed files, not entire project

## File Patterns

### Whole Project
- `make lint` or `yarn lint` - Full project
- Best for: Initial setup, major refactoring, CI/CD

### Partial/Targeted
- `make lint-staged` - Only staged files
- `make lint-changed` - Only git diff files  
- Best for: Pre-commit, quick fixes, iterative development

### Watch Mode
- `yarn typecheck:watch` - Continuous type checking
- Best for: Development workflow, real-time feedback

## Integration with Development Workflow

### Daily Development
1. Code changes
2. `make lint-changed` (quick check)
3. `git add .`
4. `git commit` (auto-runs pre-commit hooks)

### Before PR/Deployment
1. `make quality` (comprehensive check)
2. Fix all issues before pushing
3. CI/CD runs same checks

### Performance Tips
- Use staged/changed commands during development
- Full project linting only when necessary
- TypeScript watch mode for real-time feedback
- Cache enabled by default (`eslint --cache`)

## Troubleshooting

### Common Issues
- **Cache problems**: Delete `.eslintcache` and retry
- **Type errors**: Run `yarn typecheck` for detailed output
- **Pre-commit fails**: Run `make lint-staged` manually to debug
- **Performance**: Use targeted commands instead of full project

### Error Patterns
- **Import errors**: Check Nuxt auto-import configuration
- **Type mismatches**: Verify Prisma client generation
- **Vue template issues**: Ensure `vue-tsc` is running correctly
- **Unused variables**: Prefix with `_` to ignore (e.g., `_unused`)

## Best Practices

### Code Style Rules
- Use underscore prefix for unused variables (`_unused`)
- Prefer explicit imports over auto-imports when debugging
- Keep functions focused and well-typed
- Use TypeScript strict mode features

### Performance
- Run `lint-changed` during development
- Use `quality` command before commits
- Enable IDE integration for real-time feedback
- Cache linting results automatically

### Team Workflow
- Pre-commit hooks ensure consistency
- CI/CD enforces quality gates
- Shared ESLint config prevents style debates
- TypeScript catches errors before runtime

## Integration Points

### IDE Setup
Most IDEs auto-detect ESLint configuration
**Recommended Extensions**:
- ESLint
- TypeScript
- Vetur (Vue)

### CI/CD Integration
```bash
make quality  # Full quality check for CI/CD
```

### Git Hooks
- Pre-commit: Lint staged files
- Pre-push: Full quality check (optional)

This system ensures consistent code quality while maintaining development speed through targeted linting and automated checks.