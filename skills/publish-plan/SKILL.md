---
name: publish-plan
description: >-
  Publishes an HTML plan to the Cloudflare R2 bucket "plans" with the cf CLI
  and returns a public link. Use after creating any HTML plan the user asked
  for (implementation plan, project plan, roadmap, proposal, design doc as
  HTML), or when the user asks to upload, share, publish, or get a link for a
  plan. Requires the cf CLI to be logged in.
---

# Publish plan

When the user asks for a plan as HTML, finish the plan, then upload it to R2
and give them the public URL so they can open it from any device.

## Steps

1. Write the plan as one self-contained HTML file: inline CSS and JS, no local
   images or relative links, `<meta charset="utf-8">` and a viewport meta tag
   so it reads well on a phone. Save it locally first (for example in the
   project or `/tmp`).
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
