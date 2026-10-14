# Epic: nextra-docs (ND)

**Vercel's Nextra Docs Starter Kit is the smallest documentation-site template in its catalog — five MDX pages, a sidebar ordered by `_meta`, an About page and an external Contact link in the navbar, an interactive counter, full-text search — and it needs nothing from Vercel but a Node runtime at build time. On Cloudflare it is a Worker plus static assets built by OpenNext, with the Cirrus baseline's repository shape around it: an Orun intent, one component per deployable, a credential-free check lane as the merge gate, and an Orun lane that turns on when the product is linked to a workspace.**

The upstream content stays the content. What changes is the framework underneath it: the template is Nextra 2 on Next 13's pages router, which `@opennextjs/cloudflare` cannot build (it needs Next ≥ 15.5.27; the port pins 16.3.8), so the same five pages, the same sidebar, the same theme settings and the same counter component are expressed through Nextra 4 (App Router, a `content/` directory, a `[[...mdxPath]]` gateway, `_meta.ts`, Pagefind search). The port then adds the Workers build (`@opennextjs/cloudflare`), the monorepo wrapper (pnpm + Turborepo, shared tsconfig and eslint), a test package that pins the content directory and `_meta` to the upstream layout, and the deploy contract.

## Status

| Field | Value |
|-------|-------|
| Status | Draft |
| Cluster | **ND** (ND0–ND2) |
| Owner(s) | `apps/web` (the site) · `tests/web` (the content-layout tests) |
| Builds on | `cirrus-baseline` conventions (intent, components, `checks.yml` gate, gated `ci.yml`) — no bounded context of the fleet is needed |
| Upstream | [shuding/nextra-docs-template](https://github.com/shuding/nextra-docs-template) (Vercel's "Nextra Docs Starter Kit") |
| Changes | Nextra 2 → Nextra 4 (file by file in `design.md`), plus the Workers build, the monorepo wrapper, tests and the deploy contract; the page text, the sidebar order, the theme settings and the counter component are preserved |
| Decisions locked | (1) OpenNext on Workers + Static Assets, not Pages. (2) Nextra 4 on Next 16.3.8, not Nextra 2 on an old Next without OpenNext. (3) Every page is pre-rendered; `dynamicParams = false`. (4) Search is Pagefind, indexed between `next build` and the OpenNext bundle so it ships as static assets. (5) No infra root: the site binds nothing. |
| Gate | ND1 is the first user-visible rung (the site serves from a Worker). |
| Shipped as | |

## Read order

1. `design.md` — what maps to what, the Nextra 2 → 4 move, the build, what is out of scope
2. `implementation-plan.md` — the milestones and what "done" means for each
3. `risks-and-open-questions.md` — what could go wrong and what was decided
4. `IMPLEMENTATION-STATUS.md` — what actually shipped (kept distinct from intent)

## Milestones at a glance

| Milestone | What it lands | Done when |
|---|---|---|
| ND0 — the spec | this doc set and the task contracts | merged on `main` |
| ND1 — the docs on Workers | `apps/web` on Nextra 4 built by OpenNext, `tests/web`, green checks | `wrangler dev` serves every page and the search index from the worker; Checks green |
| ND2 — ready to instantiate | README, as-built status | a reader can run, test, preview and deploy it |
