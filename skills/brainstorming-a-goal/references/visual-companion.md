# Visual Companion (mockups & diagrams during brainstorming)

Use a visual when a brainstorming question is genuinely **clearer shown than told** — a layout,
wireframe, navigation structure, architecture diagram, state machine, or side-by-side design
comparison. Decide **per question**: visual for visual content, terminal for text/conceptual
questions (requirements, scope, A/B/C tradeoffs). A question *about* a UI topic is not
automatically a visual question.

**Offer just-in-time, not upfront.** The first time a question would truly benefit from a visual,
offer it in its own message ("This next part is easier if I show you — I can put mockups/diagrams
in front of you. Want me to?"). If no visual question ever arises, never offer. After acceptance,
still choose per question whether to use a visual or the terminal.

## How to render — use the best available, in this order

1. **superpowers installed → its browser companion (richest).** It serves HTML you write and
   records the user's clicks. Start it from the superpowers brainstorming skill's scripts:
   ```bash
   ls ~/.claude/plugins/cache/*/superpowers/*/skills/brainstorming/scripts/start-server.sh
   # then, with that path:
   <path> --project-dir "$(git rev-parse --show-toplevel)" --open
   ```
   Write HTML **content fragments** to the returned `screen_dir` (new file per screen, semantic
   names, never reuse), read selections from `state_dir/events` on your next turn. Follow the full
   protocol in superpowers `brainstorming/visual-companion.md` (CSS classes, event format, cleanup).
   Add `.superpowers/` to `.gitignore` if it isn't already.

2. **No superpowers → the `Artifact` tool.** Write a self-contained HTML mockup (inline CSS/JS, no
   external hosts — see the Artifact tool's constraints) and publish it; the user opens the link and
   can compare options. Iterate by editing the file and re-publishing to the same path (same URL).
   For any charts/graphs, load the `dataviz` skill first.

3. **No Artifact either → a standalone HTML file.** Write a self-contained page (inline CSS/JS) to
   `docs/plan/specs/mockups/<name>.html` and ask the user to open it in a browser. New file per
   screen; keep mockups simple (layout/structure over pixel polish); 2–4 options max per screen.

## Tips (all backends)

- Explain the question on the screen ("Which layout reads as more professional?"), not just "pick one".
- Scale fidelity to the question — wireframes for layout, polish only for polish questions.
- Iterate on the current screen before advancing; only move on once the current choice is validated.
- Selections inform the design doc — record the chosen direction into the spec (`references/design-doc-template.md`).
