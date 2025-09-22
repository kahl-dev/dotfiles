---
description: "Advisory deep-dive review (post-gate)"
aliases: ["review:simple", "simple-review"]
---

# Advisory Production Readiness Review

> 🚨 First run `/user:review:hard` to get the gatekeeper verdict. This command surfaces follow-up work once the diff is safe to ship.

@review-simple-analyzer Review all uncommitted changes in the current git repository, focusing on architectural risks, technical debt, and longer-term improvements beyond the blocking gate's verdict.
