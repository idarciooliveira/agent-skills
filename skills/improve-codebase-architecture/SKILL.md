---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, publish them as a brand-style HTML plan (unslopped, via publish-plan), then grill through whichever one you pick.
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities**: refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

This command is *informed* by the project's domain model and built on a shared design vocabulary:

- Call the Skill tool with "codebase-design" for the architecture vocabulary (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**) and its principles (the deletion test, "the interface is the test surface", "one adapter = hypothetical seam, two = real"). Use these terms exactly in every suggestion, and don't drift into "component," "service," "API," or "boundary."
- If "codebase-design" isn't installed, use these definitions: a **module** is anything with an interface and an implementation; **deep** means a lot of behaviour behind a small interface, **shallow** means the interface is nearly as complex as the implementation; a **seam** is where behaviour can change without editing in place, and an **adapter** plugs in at a seam; **locality** means a change or bug stays in one place; **leverage** is how much callers get from a small interface.
- ADRs in `docs/adr/` record decisions this command should not re-litigate.

## Process

### 1. Explore

**Scope before you scan: YAGNI.** Deepening a module pays off by making future changes to it easier, so put extra weight on the parts of the codebase that have recently changed. Decide *where* to look before you look:

- If the user named a direction (a module, a subsystem, a pain point), take it, and skip the inference below.
- Otherwise, walk back a good stretch of the commit history (`git log --oneline`) to find the codebase's hot spots, the files and areas that keep coming up, and let those paths pull your attention first. If the changes are scattered with no clear hot spot, widen the net.

Read the project's ADRs in the area you're touching first.

Then spawn a sub-agent with a fresh context window to walk the codebase. Don't follow rigid heuristics; explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow**, with an interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

### 2. Write the report as a brand-style plan

The report is always published, in the brand plan style. Load the `publish-plan` skill and follow it for the file location, style and upload:

- Save one self-contained HTML file to `~/.t3/scratch/plans/YYYY-MM-DD-<repo>-architecture-deepening.html` (create the folder if missing). Nothing lands in the repo.
- Start from `publish-plan`'s `templates/brand-plan.html`: copy its `<head>` (Inter and JetBrains Mono, tokens, base CSS) and reuse its components (`.bar`, eyebrow · h1 · meta row with a `PROPOSED` lozenge · `.kicker`, `.tbl`, `.why`, `.compare`, `.org` gradient frames). Light only, no dark mode, no Tailwind.
- Diagrams: hand-built HTML/CSS first (module boxes, lanes, gradient-framed deep modules, mass bars). Use Mermaid via CDN only where a graph or sequence reads better, with the `publish-plan` Mermaid settings (`theme: 'base'`, brand `themeVariables`, `fontFamily: 'system-ui, sans-serif'`). Each candidate gets a **before/after visualisation**. Be visual.
- Phone check: grid children get `min-width: 0`, monospace paths wrap, and two-column grids collapse under 720px.

Page layout:

- Header, then a short "where the friction is" and vocabulary pair (`.why`), then a rule-placement matrix when the same rule shows up in several layers.
- An index of candidates with their strength lozenges, linking to each card.
- For each candidate, a rounded card with:
  - **Files**: which files/modules are involved
  - **Problem**: why the current architecture is causing friction
  - **Solution**: plain English description of what would change
  - **Benefits**: explained in terms of locality and leverage, and how tests would improve
  - **Before / After diagram**: side-by-side, custom-drawn, illustrating the shallowness and the deepening
  - **Recommendation strength**: one of `Strong` (`.loz.ok`), `Worth exploring` (`.loz.wait`), `Speculative` (`.loz.no`)
- A **Top recommendation** section in a gradient-framed card: which candidate you'd tackle first and why, and the order after it.

Check every number and claim from the exploration sub-agent against the code before it goes in the report (line numbers, counts, function names).

**Use the project's domain vocabulary.** If the docs or a glossary define "Order," talk about "the Order intake module," not "the FooBarHandler," and not "the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant revisiting the ADR. Mark it clearly in the card (e.g. a warning callout: *"contradicts ADR-0007, but worth reopening because…"*). Don't list every theoretical refactor an ADR forbids.

Do NOT propose interfaces yet.

### 3. Unslop the content

Once the HTML is written, load the `unslop` skill and apply it to the report's prose: headings, kicker, card text, notes and the top recommendation. Invoking this skill counts as asking for unslop on the report, so no separate request is needed. Leave code, identifiers, file paths, numbers and diagram labels as they are, and keep every fact. Edit the HTML in place.

### 4. Publish

Publish with `publish-plan`'s `scripts/publish.sh <file> <slug>`. Always publish; never leave the report as a local file only, and never as a Claude Artifact.

Reply with the public URL on its own line, the local path, and a short summary of the candidates and the top recommendation. Then ask the user: "Which of these would you like to explore?"
