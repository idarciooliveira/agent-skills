---
name: no-comments
description: "Delete code comments that don't earn their place. Spawns fresh-eyed reviewers, audits their kills and keeps, fixes named workarounds, and offers to encode `do not remove` constraints. Use when asked to clean up, drop or review comments."
disable-model-invocation: true
---

# No comments

Spawn reviewers with the brief in [references/comment-sicko.md](references/comment-sicko.md). Act on accepted findings. Defer to the reviewer's fresh perspective.

## Scope

Use the caller's files or diff. If the caller says "the codebase", use every non-doc file. Otherwise use the current diff against the base branch (default `main`), including the working tree. Skip prose docs, generated files, vendored code, binaries.

## Steps

1. **Spawn.** Start `general-purpose` agents, passing the full brief plus the scope. Count comment lines per directory first. Split so each agent gets about 400-600 comment lines, with disjoint paths, and run them in parallel. Use default effort. Raise it only for a scope with correctness or safety suppressions.
2. **Audit.** Read every report and the real diff. Reject:
   - edits to application code, or edits outside the agent's paths
   - deletions of protected comments (see the brief's ALWAYS KEEP and hazard lists)
   - misstated `MUST KILL` reasons
   - flags that treat intentional kept code as guilty

   Rules:
   - A flag about a surprise in our own code stays actionable. Do not restore that comment.
   - A keep survives only with proof it is about something we cannot change.
   - Audit scoped lint and type suppressions the reviewer missed. A suppression that hides a correctness or safety problem is an actionable `MUST KILL`.
   - Restore a deletion only with an exact exception and scoped proof.
   - Before accepting a thin `IMPORTANT` or `do not remove` kill or keep, trace its symbol: `grep` it, then `git log -S '<text>'` and `git blame`. If a kill stays ambiguous, do not restore it. If a keep is refuted or still ambiguous, delete it.
   - Revert and rerun one rejected report once, naming the failure. If a second report is rejected, report it open and fail the run.
3. **Fix trivial flags directly.** Delete the dead path, drop the unused parameter, use the real API. If a fix needs a shape, run the `Plan` agent once for the accepted set and its surrounding code. Stop at the sketch.
4. **Implement the smallest root-cause fix in scope.** Remove every named workaround. If the root cause is out of scope, land the smallest in-scope fix and report the rest open. Fix the cause, never bolt on a symptom guard, and do not widen the scope or fix instances outside it.
5. **Constraints.** A comment saying `do not remove`, `do not change wording` or `talk to X before changing` is kept only if it is about something we cannot change. Otherwise offer the cheapest in-scope type, runtime check, test or CI lint, and wait for approval. If approved, encode it, then delete the comment. If not, delete it, report the constraint as unenforced, and sketch the out-of-scope work. In unattended runs, encode only with caller pre-approval.
6. **Verify.** Run what exists locally: `bash -n`, `py_compile`, YAML parse, `terraform fmt -check`, `helm template` before and after, and unit tests. Confirm the diff touches only comment lines (trailing-comment edits are the expected exception). Leave changes uncommitted unless asked.
7. **Report.** Give the deletion count, restored comments, reruns, Plan sketch, fixes, encoding offers, encodings, unenforced constraints, and other open work.
