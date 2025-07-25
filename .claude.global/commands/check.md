---
command: check
description: Aggressive code quality enforcement - zero tolerance for any issues
---

# 🚨 AGGRESSIVE CODE QUALITY CHECK

When the user runs `/check`, you will perform EXHAUSTIVE code quality checks and FIX EVERYTHING. This is not a reporting task - this is a FIXING task.

## YOUR MISSION

1. Run comprehensive checks for JavaScript/TypeScript/Vue files
2. Find EVERY issue - no matter how minor
3. Fix EVERYTHING immediately
4. Re-run checks until perfection is achieved
5. NEVER stop until all checks pass

## PACKAGE MANAGER DETECTION

FIRST, detect which package manager the project uses:
- Check for `yarn.lock` → use `yarn`
- Check for `pnpm-lock.yaml` → use `pnpm`  
- Check for `package-lock.json` → use `npm`
- Check for `bun.lockb` → use `bun`
- Default to `npm` if no lock file found

Use the detected package manager for ALL operations below.

## CHECKS TO PERFORM

### 1. ESLint (JavaScript/TypeScript/Vue)
- Run ESLint on ALL .js, .jsx, .ts, .tsx, .vue, .mjs, .cjs files
- First attempt `eslint --fix` 
- For remaining issues, fix them manually
- NO WARNINGS ALLOWED - even style issues must be fixed

### 2. TypeScript Type Checking
- Run `tsc --noEmit` on all TypeScript files
- Run `vue-tsc --noEmit` on Vue files if available
- Fix EVERY type error
- Add proper types where missing
- Remove all `any` types unless absolutely necessary

### 3. Tests
- Run tests with detected package manager (`yarn test`, `pnpm test`, `npm test`, etc.)
- Fix all failing tests
- If no test script exists in package.json, suggest adding one:
  - "Consider adding tests with: `jest`, `vitest`, or `mocha`"
  - DO NOT install or create a test system
  - Just note it as a recommendation for later

### 4. Security Audit
- Run security audit with detected package manager:
  - `yarn audit` (yarn)
  - `pnpm audit` (pnpm)
  - `npm audit` (npm)
  - `bun audit` (bun)
- Fix ALL vulnerabilities:
  - `yarn upgrade --latest` or `yarn upgrade-interactive` (yarn)
  - `pnpm update` (pnpm)
  - `npm audit fix --force` (npm)
- Update packages as required
- NO vulnerabilities allowed

### 5. Build Verification
- Run build with detected package manager:
  - `yarn build` (yarn)
  - `pnpm build` (pnpm) 
  - `npm run build` (npm)
  - `bun run build` (bun)
- Fix any build errors
- Ensure build completes successfully

## EXECUTION WORKFLOW

1. **Package Manager Detection**: FIRST check for lock files to determine package manager
2. **Initial Scan**: Run ALL checks in parallel using Task tool with detected package manager
3. **Create Fix Tasks**: Use TodoWrite to track every single issue found
4. **Aggressive Fixing**: 
   - Spawn multiple agents if needed
   - Fix issues in parallel where possible
   - Use Edit/MultiEdit aggressively
   - Use correct package manager for any installs/updates
5. **Verification**: Re-run ALL checks after fixes
6. **Repeat**: Continue until ZERO issues remain

## FORBIDDEN BEHAVIORS

❌ DO NOT just report issues
❌ DO NOT make excuses about why something can't be fixed
❌ DO NOT stop before everything is perfect
❌ DO NOT ignore warnings - treat them as errors
❌ DO NOT leave any TODO comments without implementing them

## EXAMPLE EXECUTION

```
🚨 STARTING AGGRESSIVE CODE QUALITY CHECK

Running parallel checks...
[Use Task tool to run all checks simultaneously]

Found issues:
- 12 ESLint errors
- 8 TypeScript errors
- 3 failing tests
- 2 security vulnerabilities
- Build failing

Creating fix tasks...
[TodoWrite with all issues]

FIXING EVERYTHING NOW:
- Agent 1: Fixing ESLint errors...
- Agent 2: Resolving type errors...
- Agent 3: Fixing failing tests...
- Agent 4: Updating vulnerable packages...

[Continue aggressively until perfection]

✅ ALL CHECKS PASSING - CODE IS NOW PERFECT
```

## REMEMBER

This is about achieving PERFECTION. Every semicolon, every type annotation, every style rule - EVERYTHING must be perfect. There are no acceptable compromises.

When in doubt, FIX IT. When it seems minor, FIX IT. When it's just a warning, FIX IT.

The only acceptable outcome is: ALL GREEN, ZERO ISSUES.