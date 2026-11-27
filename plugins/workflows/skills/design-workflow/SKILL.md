---
name: design-workflow
description: Orchestrates every UI, UX and visual design task so the design skills work together instead of clashing. Use for any request to design, redesign, build, polish, restyle, animate, critique or audit a UI, page, screen, dashboard, component, landing page or website. Roles - product UI (dashboards, app screens, components, forms) is led by impeccable; landing and marketing sites are led by taste-skill (hallmark only if named) with impeccable only as an optional audit; ui-ux-pro-max is a reference library and never leads; one lead and one critic per task; the project's tokens, components and DESIGN.md beat every skill.
---

# Design workflow

Several design skills, one job each. Pick **one lead** per task, consult the **library** as needed, and run **one critic** per pass. Never run two builders on the same page.

## Who decides (highest wins)

1. The project's own rules, tokens and components: theme and design-token files (`globals.css`, `tailwind.config.*`, `theme.*`, `tokens.*`), its component library (shadcn/ui, MUI, Chakra, a house kit, SwiftUI or Flutter theme), and repo rules about UI.
2. `DESIGN.md` (and `PRODUCT.md`) at the repo root: the one design doc per repo, written and kept current by impeccable (`document`).
3. The lead skill's choices.
4. ui-ux-pro-max suggestions.

If a skill suggests a palette, font or spacing scale that contradicts 1 or 2, keep the project's. New palettes and fonts only for greenfield work with no tokens and no DESIGN.md.

## Roles

| Skill | Role | Use it for | Never |
|---|---|---|---|
| **impeccable** | Lead designer for product UI | dashboards, app screens, components, forms, flows, native screens. `shape`/`craft` new UI; `polish`/`bolder`/`quieter`/`distill`/`animate` existing UI; `critique`/`audit`; `document` DESIGN.md | leading landing pages when taste-skill or hallmark leads |
| **ui-ux-pro-max** | Reference library | searching UX guidelines, chart choice, accessibility, stack rules (React, Next.js, shadcn, Vue, React Native, Flutter, SwiftUI...). Palettes and fonts only for greenfield work | building on its own; `--persist` (it creates a second design doc, `design-system/MASTER.md`) |
| **taste-skill** (`taste-skill:design-taste-frontend`) | Lead for marketing and company websites | landing, company, product-marketing and pricing pages, with its own checker gate | product UI inside an app |
| **hallmark** (`hallmark:hallmark`, optional) | Alternate lead for brand-new standalone pages | only when the user names Hallmark, or a new page where taste-skill doesn't fit | existing designs unless named; "lock the system" when DESIGN.md exists |
| **diagram-design** (`diagram-design:diagram-design`) | Diagrams only | architecture, flows, sequences, ERDs | UI |

If Anthropic's `design` plugin is installed, its skills support the pipeline but never lead or critique visuals:
- `design:accessibility-review`: a dedicated WCAG pass when asked.
- `design:ux-copy`: microcopy and error text.
- `design:design-handoff`: developer specs.
- `design:design-system`: auditing token and component naming.

`design:design-critique` is not used. impeccable `critique` is the visual critic; it reviews against the brief and DESIGN.md, not its own taste.

A project-level copy of a skill (for example `.claude/skills/ui-ux-pro-max/` inside the repo) wins over the global one.

If a skill isn't installed, do its step yourself with the same intent and keep going.

## Pipelines

**Product UI** (dashboard, screen, component, form):
1. Context: project rules, tokens, existing components, DESIGN.md and PRODUCT.md (impeccable `context`).
2. Reference: a ui-ux-pro-max search for the specific question (chart type, filter pattern, accessibility, stack rule).
3. Build or change: impeccable `shape` → `craft` for new UI, or the matching refine verb (`polish`, `distill`, `animate`...) for existing UI. Always use the project's components and tokens.
4. Critique: impeccable `critique` or `audit`, then fix what matters.
5. Verify: look at the rendered result at real sizes (mobile and desktop), then run the project's checks (`workflows:pre-pr` quick).
6. If the visual system changed: impeccable `document` updates DESIGN.md.

**Landing or marketing site:** taste-skill end to end (or hallmark if named), ui-ux-pro-max for UX reference, and taste's own gate as the critic. Use impeccable `audit` only if asked for a second opinion.

**Design review only:** impeccable `critique`. Use the taste or hallmark audit only for pages they built.

## Housekeeping

- Scratch folders `.impeccable/`, `.taste-skill/`, `.hallmark/` and any `design-system/` the skills create are local working files. Add them to `.git/info/exclude` and never commit them.
- Commit DESIGN.md and PRODUCT.md only when the user asks.
