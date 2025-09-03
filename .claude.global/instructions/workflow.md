## Core Workflow: Research → Plan → Implement → Validate → Document

**Start every feature with:** "Let me research the codebase and create a plan before implementing."

1. **Research** - Understand existing patterns and architecture
2. **Plan** - Propose approach and verify with you
3. **Implement** - Build incrementally with validation
4. **Validate** - ALWAYS run formatters, linters, and tests
5. **Document** - MANDATORY: Update all related documentation (see @instructions/documentation-maintenance.md)

## Long-Running Commands - Use Background Execution

**ALWAYS use `run_in_background: true` for:**
- Test suites that might exceed 2 minutes (`yarn test:run`, `npm test`, `vitest`, `jest`)
- Any command with `--watch` flag
- Development servers (`npm run dev`, `yarn dev`, `pnpm dev`, `bun dev`)
- Make commands: `make dev`, `make test`, `make watch`, `make serve`
- Build processes over 30 seconds
- Docker commands (`docker-compose up`, `docker build`)

**Workflow:**
1. Start command with `run_in_background: true`
2. Continue working on other tasks
3. Monitor output with `BashOutput` tool periodically
4. Clean up with `KillBash` when done

**Example:**
```bash
# Start tests in background
make test  # with run_in_background: true
# Returns: "Command running in background with ID: bash_1"

# Check output later
BashOutput(bash_id="bash_1")

# Kill when done
KillBash(shell_id="bash_1")
```

## Development Partnership

We build production code together. I handle implementation details while you guide architecture and catch complexity early.