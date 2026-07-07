# Adding Skills

Guide for contributing new skills to this repository.

## Create a skill folder

Each skill lives at `skills/<skill-name>/` with a required `SKILL.md` file:

```
skills/my-skill/
├── SKILL.md          # required
├── scripts/          # optional — executable helpers
├── references/       # optional — long-form docs loaded on demand
└── examples.md       # optional — usage examples
```

### Scaffold options

**Option A — copy an existing skill:**

```bash
cp -r skills/e-kwanza skills/my-skill
# then edit skills/my-skill/SKILL.md
```

**Option B — use the skills CLI:**

```bash
npx skills init my-skill
mv my-skill skills/my-skill
```

## SKILL.md requirements

Every skill needs YAML frontmatter with `name` and `description`:

```markdown
---
name: my-skill
description: What this skill does and when to use it. Write in third person. Include trigger terms the agent should match on.
---

# My Skill

## Instructions
...
```

### Frontmatter rules

| Field | Rules |
|---|---|
| `name` | Lowercase letters, numbers, hyphens only. Max 64 chars. Must match the `--skill` install flag. |
| `description` | Non-empty, max 1024 chars. Third person. Include both **what** the skill does and **when** to use it. |

### Optional: hide work-in-progress skills

```markdown
---
name: my-wip-skill
description: ...
metadata:
  internal: true
---
```

Internal skills are only visible when `INSTALL_INTERNAL_SKILLS=1` is set.

## Writing guidelines

- Keep `SKILL.md` under ~500 lines. Move detailed reference material to `references/`.
- Link supporting files one level deep from `SKILL.md` (e.g. `[api-reference.md](references/api-reference.md)`).
- Use `scripts/` for fragile or repetitive operations (signature generation, validation, etc.).
- Write descriptions with trigger terms so agents auto-detect the right skill.

## Verify before pushing

```bash
# List all skills the CLI can discover
npx skills add . --list

# Test install for your skill
npx skills add . --skill <skill-name> -a cursor -y

# Confirm it landed
npx skills list
```

## Add to the README catalog

After adding a skill, update the **Available skills** table in [README.md](../README.md) with the skill name, a one-line description, and its install command.

## Checklist

- [ ] Folder created at `skills/<skill-name>/`
- [ ] `SKILL.md` has valid `name` and `description` frontmatter
- [ ] `SKILL.md` is concise; long docs are in `references/`
- [ ] `npx skills add . --list` shows the new skill
- [ ] README catalog table updated
