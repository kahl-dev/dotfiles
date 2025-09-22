---
description: "Strict production gate (staged + unstaged changes)"
aliases: ["review:hard", "hard-review"]
allowed-tools:
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git show:*)
  - Bash(git ls-files:*)
  - Bash(cat*)
  - Bash(rg*)
---

@review-hard-auditor Review the pending changes and report on production readiness.

## Context

- Current branch: !`git branch --show-current`
- Pending change summary (staged + unstaged): !`git status --short`
- Diffstat for all pending work: !`git diff --stat`
- Changed files (unstaged): !`git diff --name-only`
- Full diff (unstaged): !`git diff`
- Changed files (staged): !`git diff --cached --name-only`
- Full diff (staged): !`git diff --cached`
- Newly added but untracked files: !`git ls-files --others --exclude-standard`
- Current file contents (unstaged): !`git diff --name-only | sort -u`
- Current file contents (staged): !`git diff --cached --name-only | sort -u`
- Current file contents (untracked): !`git ls-files --others --exclude-standard | sort -u`
- Fallback heredocs: !`rg -n '<< EOF' .claude.global/hooks/user_prompt_submit.sh`
- Prompt writes: !`rg -n '\$prompt' .claude.global/hooks/user_prompt_submit.sh`

> For each path above, run `cat <path>` (or `rg` for symbol searches) to inspect the full file contents.


> ⚠️ If the command output is very large, summarise what is relevant rather than pasting everything verbatim.

## Task

Act as a production readiness reviewer. Inspect **every** staged and unstaged change shown above (including newly added files) and decide whether the work is safe to ship. For each file, check both the primary logic and any fallback/error paths. Do not assume changes are safe—prove they are.

### Checklist
1. **Security & Privacy** – secrets, authZ/authN, sensitive data exposure, input sanitisation (including logs, JSON, shells).
2. **Operational Reliability** – error handling, retries, logging/observability, failure modes, rollback strategy, feature flags.
3. **Data Lifecycle** – persistence, retention/cleanup, quotas, migrations, resource limits.
4. **Performance & Scalability** – latency, CPU/memory/disk usage, fan-out calls, cache usage.
5. **Configuration & Rollout** – env vars, backward compatibility, dependency changes, submodules.
6. **Testing & Verification** – automated coverage, manual test plan, monitoring to watch post-deploy.
7. **Documentation & Ownership** – release/runbook updates, follow-up work, responsible teams.

Call out any assumption you have to make. Highlight missing information you need to sign off.

## Deliverable

Produce a concise, actionable report that covers **every** changed file:

- Begin with **Blocking issues** (file path + line number) and explain the production risk. Only say "No blockers found" when zero blocking/high-risk issues remain and you would ship without changes today.
- Then list **High / Medium / Low severity** findings. Every changed file must be mentioned at least once; if a file truly has no concerns, explicitly state that with the path and why it is safe.
- Record what **testing was performed or is missing**, and the follow-up actions needed.
- Document any **assumptions or unknowns** that could affect the ship decision.
- Finish with a verdict: `Ready`, `Ready with Follow-ups`, or `Not Ready`. If **any** blocker exists—or you recommend fixing something *before* commit—the verdict must be `Not Ready`. Choose `Ready` only when zero blockers/high risks remain.

Focus on risk evaluation and mitigation. Do not rubber-stamp; justify every conclusion with concrete evidence from the files.
