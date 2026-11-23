# Comment Sicko brief

Pass this whole file to each reviewer, with the scope paths and the repo root. Tell it: do not commit, stash or checkout; leave edits uncommitted; work only in the repo.

You are a fresh-eyed reviewer who deletes code comments that don't earn their place. Review every comment in your paths. Edit only comment lines and trailing comments. Never change code, values or ordering, and do not touch blank-line structure beyond removing a comment (collapse a blank line only if it would leave a double blank or an orphan section gap).

## MUST KILL

- Comments that restate what the next line, key or task name already says. Section banners are the usual case.
- History or change narration: `added for X`, `was Y before`, `new`, `fixed`, `previously…`.
- Ticket, PR, ADR, step or WP number breadcrumbs that only say "see X" with no reason.
- Commented-out code or dead config.
- TODO or FIXME with no concrete action.
- Comments that explain a workaround for a surprise in our own code. Report it as an actionable flag; do not keep the comment.
- Vague, obsolete or untrue comments. Verify against the code before keeping anything.
- Docstrings that only restate the function name or signature.

## KEEP

Keep a comment that carries a non-obvious WHY the code cannot show:
- a real external constraint: tool or version quirk, upstream bug, OS, kernel or runtime behavior
- security rationale
- an ordering dependency
- the unit or derivation of a non-obvious value

A keep must be about something we cannot change in code. Tighten verbose keeps to 1-2 lines.

## ALWAYS KEEP (tool-parsed or structural)

- Shebangs and modelines.
- Lint and type directives: `shellcheck`, `yamllint`, `noqa`, `nosec`, `tflint-ignore`, `checkov`, `trivy`, `eslint-disable`, `@ts-*`.
- Bot directives and pinned-version comments: `renovate:`, and the version comment after a pinned action SHA.
- `yaml-language-server`, `syntax=`, `diagram:`, SPDX and license headers, sops metadata.
- Markers that another script reads: grep the repo before deleting a header or marker comment.

## HAZARDS (do not edit; report instead)

- Comments a program prints at runtime: leading `#` blocks that `usage()` or `--help` print, comments written into generated files or registry files, strings.
- Comments inside content that feeds a checksum or hash, such as Helm `checksum/*` annotations over a ConfigMap, embedded scripts, nginx or app config, or files a chart reads with `readFile`. A comment-only edit there restarts pods. Prove it is safe by comparing `helm template` output before and after, or leave the file alone and report it.
- Comments CI enforces, such as "keep this file ASCII".

## Constraints and suppressions

- Constraint comments (`do not remove`, `do not change wording`, `talk to X before changing`): keep if they are about something outside our control. Otherwise delete and report UNENFORCED CONSTRAINT with the cheapest check that could encode it. Do not encode anything yourself.
- If a scoped suppression looks like it hides a real correctness or safety problem, do not delete it. List it as OPEN.
- If a comment is ambiguous, trace its symbol with `grep` and `git log -S`. If it is still ambiguous and not tool-parsed, delete it.

## Verify before reporting

Run whatever exists locally and skip what is missing: `bash -n`, `shellcheck`, `python3 -I -m py_compile` (delete any `__pycache__` you create), a YAML parse, `terraform fmt -check`, `helm template` before vs after, and fast unit tests. Do not ssh, apply, deploy or start clusters. Confirm only comment lines changed:

    git diff -U0 | grep '^[-+]' | grep -v '^[-+][-+]' | grep -vE '^-\s*(#|//|;|\{#|/\*|\{\{/\*)'

Explain every non-comment line it shows.

## Report (under 350 words)

- Files touched.
- Comment lines deleted, and comments tightened.
- Up to 10 notable KEEPs, one line of reason each.
- Suppressions found, and whether they look safe.
- UNENFORCED CONSTRAINTS, each with its cheapest encoding.
- OPEN items: our-code problems you noticed that a comment-only scope cannot fix.
- Files you left alone because of the hazard list.
- Verification results, including which tools were missing.
