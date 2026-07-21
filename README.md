# Agent Skills

Custom agent skills for our team. Each skill is a folder with a `SKILL.md` file that teaches AI coding agents how to handle specific workflows — payment integrations, deployment patterns, framework conventions, and more.

Skills follow the [Agent Skills](https://agentskills.io/) format and install via the [skills.sh](https://skills.sh) CLI.

[![skills.sh](https://skills.sh/b/idarciooliveira/agent-skills)](https://skills.sh/idarciooliveira/agent-skills)

## Quick install

```bash
# List available skills
npx skills add idarciooliveira/agent-skills --list

# Install all skills (project scope, default)
npx skills add idarciooliveira/agent-skills

# Install one skill
npx skills add idarciooliveira/agent-skills --skill ekwanza

# Install globally (available across all projects)
npx skills add idarciooliveira/agent-skills -g

# Cursor only, non-interactive
npx skills add idarciooliveira/agent-skills --skill ekwanza -a cursor -y
```

### Local development

Before pushing to GitHub, install from a local clone:

```bash
npx skills add . --skill ekwanza
npx skills add . --skill payment-adapters
```

## Available skills

| Skill | Description | Install |
|---|---|---|
| `ekwanza` | Integrate É-kwanza / pay4all / AppyPay — tickets, QR, KWiK/IBAN, webhooks, GPO charges, plus production status-mapping lessons | `npx skills add idarciooliveira/agent-skills --skill ekwanza` |
| `emis` | Integrate EMIS GPO — OAuth2/mTLS, WebFrame, Multicaixa Express, authorizations/captures/refunds, processor declines | `npx skills add idarciooliveira/agent-skills --skill emis` |
| `payment-adapters` | Wallet orchestration — CashIn/Withdraw ports, Pending vs Rejected routing, reconciliation, dual-rail env, clearing/escrow glossary, cutover checklist | `npx skills add idarciooliveira/agent-skills --skill payment-adapters` |

## Where skills are installed

After installation, skills land in agent-specific directories. For **Cursor**:

| Scope | Flag | Path |
|---|---|---|
| Project | (default) | `.agents/skills/<skill-name>/` |
| Global | `-g` | `~/.cursor/skills/<skill-name>/` |

Confirm installation:

```bash
npx skills list
```

## Usage

Once installed, agents pick up skills automatically when the task matches the skill's description. You can also mention the skill explicitly in chat (e.g. "use the ekwanza skill to add payment webhooks").

For wallet bugs (stuck Pending, UNKNOWN vs REJECTED, clearing seeds), prefer **`payment-adapters`** together with the relevant vendor skill (`emis` or `ekwanza`).

## Adding a new skill

1. Create a folder at `skills/<skill-name>/` with a `SKILL.md` file.
2. Follow the conventions in [docs/adding-skills.md](docs/adding-skills.md).
3. Verify with `npx skills add . --list` before pushing.

## Updating installed skills

Re-run the install command or use the update command to pull the latest version:

```bash
npx skills update ekwanza
npx skills update emis
npx skills update payment-adapters
```

## Repository layout

```
agent-skills/
├── README.md
├── docs/
│   └── adding-skills.md
└── skills/
    ├── e-kwanza/          # install name: ekwanza
    │   ├── SKILL.md
    │   ├── scripts/
    │   └── references/
    ├── emis/
    │   ├── SKILL.md
    │   └── references/
    └── payment-adapters/
        └── SKILL.md
```

New skills are added as sibling folders under `skills/`.

## Publishing

There is no separate publish step. Push this repo to GitHub and share the install command. After people install from it, the repo can appear on [skills.sh](https://skills.sh) automatically.

Repository: https://github.com/idarciooliveira/agent-skills
