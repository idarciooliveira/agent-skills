---
name: publish-plan
description: >-
  Publishes an HTML plan to the Cloudflare R2 bucket "plans" with the cf CLI
  and returns a public link. Use after creating any HTML plan the user asked
  for (implementation plan, project plan, roadmap, proposal, design doc as
  HTML), or when the user asks to upload, share, publish, or get a link for a
  plan. Also lists and downloads plans already in the bucket: use when the
  user asks to find, fetch, open, reread or update a plan/guide published
  before. Requires the cf CLI to be logged in.
---

# Publish plan

When the user asks for a plan as HTML, finish the plan, then upload it to R2
and give them the public URL so they can open it from any device.

## Steps

1. Write the plan as one self-contained HTML file: inline CSS and JS, no local
   images or relative links, `<meta charset="utf-8">` and a viewport meta tag
   so it reads well on a phone. Save it locally first in
   `~/.t3/scratch/plans/YYYY-MM-DD-<slug>.html` (create the folder if missing).
   Always use the light brand style in [Style](#style). No dark mode.
2. Run the script next to this file:

   ```bash
   scripts/publish.sh path/to/plan.html [slug]
   ```

   The slug defaults to the file name. The script uploads to
   `plans/YYYY-MM-DD/<slug>-<random>.html` with `text/html; charset=utf-8`,
   checks the URL returns 200, and prints it as the last line of stdout.
3. Send the URL to the user in your final reply, as a plain link on its own
   line. Also mention the local file path.

To update a plan, run the script again and share the new URL. Each upload gets
a new key, so old links keep showing the old version.

## Fetch existing plans

Use `scripts/plans.sh` when the user asks for a plan or guide published
earlier ("get the onboarding plan", "open last week's architecture doc").

```bash
scripts/plans.sh list [filter]                 # newest first: date, size, public URL
scripts/plans.sh get <key|url|filter> [out_dir]  # downloads, prints local path
```

- A filter is a case-insensitive substring of the key, such as `onboarding`,
  `architecture` or `2026-11`. `get` with a filter takes the newest match.
- `get` saves to `~/.t3/scratch/plans/r2/<YYYY-MM-DD>/<key>.html` by default.
- Several versions of one slug can exist (each upload is a new key). Pick the
  newest unless the user names a date, and list the others if it's ambiguous.
- To read a plan, `get` it and read the local file. To change one, edit a
  copy in `~/.t3/scratch/plans/` and publish it again with `publish.sh`; share
  the new URL. Don't delete old objects unless the user asks.

## Style

Every plan uses one look: the brand style, light only. Start from the template
next to this file, `templates/brand-plan.html`: copy its `<head>` (fonts, tokens, base CSS)
and reuse its components. Don't add `prefers-color-scheme: dark` rules or
theme toggles. Add `<meta name="color-scheme" content="light">`.

- Page: white background, a 6px gradient bar on top (`.bar`), content in
  `main` at max 960px. Near-black ink `#110700`, muted `#6b6270`, thin rules
  `rgba(17,7,0,.12)`.
- Type: Inter for text (15px body, 30px bold h1, 18px h2), JetBrains Mono for
  code. Uppercase letter-spaced `.eyebrow` above the title.
- Brand: purple `#AB00FF`, gradient purple → magenta `#FF1CD0` → orange
  `#FFA050` (`--grad`). Use the gradient for the top bar and for 2px framed
  hero boxes (`.org`); soft lilac `#faf6fd` for highlighted cards.
- Shapes: rounded cards (18–22px radius), pills everywhere: status lozenges
  `.loz.ok|.no|.wait` (green / grey / amber), chips with a role badge
  (`.chip.v` grey, `.chip.e` black), folder tiles with a coloured tab.
- Header pattern: eyebrow · h1 · meta row with a status lozenge (PROPOSTO,
  etc.), reviewer and date · one-line `.kicker` with the goal.
- Tables in `.tbl` (rounded border, uppercase small headers). Two-column card
  grids (`.compare`, `.why`) collapse to one column under 720px.

Starter tokens (full CSS in the template):

```html
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
  :root { color-scheme: light;
    --ink:#110700; --muted:#6b6270; --line:rgba(17,7,0,.12); --bg:#ffffff; --soft:#faf6fd;
    --purple:#ab00ff; --purple-d:#8a00cc; --magenta:#ff1cd0; --orange:#ffa050;
    --grad:linear-gradient(90deg,var(--purple),var(--magenta) 55%,var(--orange));
    --ok-bg:#e4f5ea; --ok:#17703f; --no-bg:#efedf0; --no:#5d5662; --wait-bg:#fff2d4; --wait:#8a5a00; }
  body { background:var(--bg); color:var(--ink); font-family:"Inter",system-ui,sans-serif; font-size:15px; line-height:1.55; }
  .bar { height:6px; background:var(--grad); }
  code { font-family:"JetBrains Mono",ui-monospace,monospace; }
</style>
```

Mermaid: `startOnLoad: true`, `theme: 'base'`, `themeVariables` from the
tokens above (`primaryColor` = `#faf6fd`, `primaryBorderColor` = purple,
`lineColor` = muted, `clusterBkg` = white). Use a system sans for diagrams
(`fontFamily: 'system-ui, sans-serif'`), not the web font: a font that loads
after Mermaid measures labels truncates them, and calling `mermaid.run()`
late stacked every diagram into the first one. Prefer HTML/CSS diagrams
(layers, chips, folder tiles) when they read as well.

Phone check: give grid children `min-width: 0` and let monospace paths wrap
(`overflow-wrap: anywhere`), or long file names push the page sideways.

## Details

- Bucket: `plans`. Override with `PLAN_BUCKET=<name>`.
- Public host: the bucket's custom domain if one is attached, else its r2.dev
  domain. The script looks this up each run, so adding a custom domain later
  needs no change here.
- The random suffix keeps links hard to guess. Anyone with a link can still
  open it, so don't put secrets, credentials, or customer data in a plan.
- r2.dev is rate-limited and meant for light use. That's fine for sharing plans.

## Troubleshooting

| Error | Fix |
|---|---|
| `cf CLI not found` | `npm i -g cloudflare`, then `cf auth login` |
| `cannot read bucket` | Check `cf auth whoami`. If logged out, ask the user to run `cf auth login`. |
| `has no public access` | Ask the user first, then `cf r2 buckets domains managed update plans --enabled true --force` |
| HTTP warning after upload | r2.dev sometimes needs a few seconds. Retry `curl -I <url>` before telling the user it failed. |

Use `cf cli search "<task>"` to find other cf commands. Don't chain `--help`
calls to explore.
