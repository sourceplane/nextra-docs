# nextra-docs (ND) — Implementation status

As-built ≠ intent. This file records what actually shipped, and every place
the code departed from `design.md` or from the upstream template.

| Milestone | State | PR |
|---|---|---|
| ND0 — the spec | ✅ Shipped | [#1](https://github.com/sourceplane/nextra-docs/pull/1) |
| ND1 — the docs on Workers | ✅ Shipped | [#2](https://github.com/sourceplane/nextra-docs/pull/2) |
| ND2 — ready to instantiate | ✅ Shipped | [#3](https://github.com/sourceplane/nextra-docs/pull/3) |
| ND3 — a baseline | 🟡 In progress | this PR (ND-4), to be tagged `baseline-v1` |

## Departures from the upstream template

### Nextra 2 / Next 13 → Nextra 4 / Next 16.3.8

The big one; `design.md` §3 has the file-by-file table. In short:
`pages/*.mdx` → `content/*.mdx`; `pages/_meta.json` → `content/_meta.ts`;
`theme.config.tsx` → `app/layout.tsx` (`Layout` / `Navbar` / `Footer`
props); `next.config.js` → `next.config.mjs` (`nextra({})` + standalone
output); new `app/[[...mdxPath]]/page.tsx` and `mdx-components.tsx`;
FlexSearch → Pagefind. What stayed identical: the text of the five pages,
the sidebar order and titles, the navbar entries (`About`, `Contact ↗`
external), the logo `My Project`, the project and chat links, the docs
repository base, the footer `Nextra Docs Template`, the code block with
filename, highlighted line and copy button, the `counters.module.css`, the
body of `counters.tsx`, dark mode, search.

### `asIndexPage: true` front matter on `content/advanced.mdx`

Nextra 2 made a file beside a folder of the same name the folder's own
page implicitly. Nextra 4's page map makes it the folder's `index` child
unless the front matter says `asIndexPage: true`. The text is unchanged.

### The inline counter in `another.mdx` is a client component file

Upstream defines `export const Counter` with `useState` inside the MDX.
Nextra 4 renders MDX on the server, so the same code lives in
`components/counter.tsx` under `'use client'` and the page imports it.
`components/counters.tsx` gains the `'use client'` directive on line 1;
its body and the CSS module are byte-for-byte upstream.

### `newWindow: true` dropped from the `contact` entry of `_meta`

Nextra 4's `_meta` schema is strict and does not know the key; its anchor
opens every external `href` with `target="_blank"` regardless, so the link
behaves as upstream.

### `dynamicParams = false` on `app/[[...mdxPath]]/page.tsx`

Every page in the page map is pre-rendered; anything else is a 404. A
Worker has no filesystem at request time.

### Title template set explicitly

Nextra 2's docs theme applied `%s – Nextra` by default; Nextra 4 takes the
title from Next's metadata, so `app/layout.tsx` sets that template (and
`My Project` as the default) to keep the same `<title>`.

### zod pinned to `~4.3.6` for the Nextra packages

A pnpm override in `pnpm-workspace.yaml` (`risks` ND-C). Not an upstream
file; recorded because a plain `pnpm add nextra` would not reproduce the
working build.

### Not carried over

`.github/screenshot.png` and the Vercel deploy button. ND1–ND2 kept the
upstream README verbatim as `apps/web/README.md`; ND3 replaced it (below).

### The site's name and repository come from `app/site.ts` (ND3)

`SITE_NAME` replaces the template's two names — `My Project` (the logo and
the default title) and `Nextra` (the `%s – Nextra` title template) — and the
footer's `Nextra Docs Template`, with one; `SOURCE_URL` replaces the
upstream repository the navbar's GitHub link and the docs repository base
pointed at (`shuding/nextra-docs-template`) with this repository, so a site's
"Edit this page" and feedback links open its own repository
(`DOCS_REPOSITORY_BASE` = `SOURCE_URL` + `/tree/main/apps/web`). They are the
seam the baseline's rename rewrites. The chat link (`discord.com`), the
Contact link and the page text are the template's and unchanged.

### `apps/web/README.md` is the app's, not the template's (ND3)

The upstream README advertised a Vercel demo and a "Deploy with Vercel"
button, and it ships into every site. It now describes the app and credits
the template (MIT).

## Departures from the port (ND3)

| What | Before | After | Why |
|---|---|---|---|
| `apps/web` smoke | `grep 'My Project'` | the docs navbar on `/`, and `/_pagefind/pagefind-entry.json` is the search index | the name is the owner's, and HTML-escaped when it carries `&` or `'`; the index is what a broken build loses first |
| `ci.yml` gate | `vars.ORUN_CI == 'true'` | skip only while `intent.yaml` names `ws_CHANGE_ME` | a bootstrap cannot set a repository variable |
| `checks.yml` triggers | push to main + pull requests | pull requests + `workflow_dispatch` | a push to main must start `ci.yml` alone (risks ND-L) |
| stack-tectonic | 0.18.2 | 0.19.0 | first-deploy retry (0.19.0); NOT 0.20.0's lane-scoped install (risks ND-K) |
| orun lane pin | v2.78.0 | v2.78.4 | cirrus-baseline's and portfolio-starter-kit's pin |
| `intent.yaml` | terraform `parameterDefaults`; docs pages under `specs/` | neither; docs pages `ai/context/*` | no terraform component; the pages must exist in a site |
| discovery roots | `infra/`, `packages/` absent | `infra/.gitkeep`, `packages/.gitkeep` | `intent.yaml` discovers them; a bootstrap places the same files |
| `tasks/ND-1..3` | no `metadata` | `metadata.name` and `title` | `orun work check` (≥ v2.79) wants them, as the portfolio's did |

## Verified (ND3)

- `orun new --status` reads the blueprint at v2.58.11 (the bootstrap floor)
  and v2.79.0; `orun validate` and `orun work check` clean.
- `testing/{manifest,phases,coverage,rebrand,retouch,bootstrap-defer}.test.sh`
  green.
- `testing/leak.test.sh` (v2.58.11 and v2.79.0): 57 files derived; nothing of
  the factory, nothing local or built (an operator's `_pagefind` included);
  no provenance prose.
- `testing/placement.test.sh` (v2.58.11 and v2.79.0; offline bootstrap,
  fixture "Sam's Docs & Guides" / `acme-inc/acme-docs`): three landings;
  rebrand `--verify` clean; workspace re-tenanted, `work:` stripped,
  promotion and dev lanes restored; deployment record rendered; the site's
  own `orun plan` for the 02-site merge deploys `web` to stage and prod side
  by side with the site's Worker name, smoke and secret refs; `--resume`
  changes nothing.
- `testing/e2e.test.sh` (v2.78.4 and v2.79.0): the scaffold's landing and the
  finished site pass the Checks sequence; in the job tree staged as orun
  stages it on stack-tectonic 0.19.0 (install inside the tree) the stage
  lane's `install-workspace-dependencies`, `build-app` (Turbopack, Pagefind,
  OpenNext), `verify-build-output` and `deploy-dry-run` pass and the staged
  build's own index holds all 5 pages; `wrangler dev` serves the built
  Worker; the component's own smoke passes; `/` (title, logo and footer the
  escaped site name, GitHub and "Edit this page" links on
  `github.com/acme-inc/acme-docs`), the four other pages, a 404 and
  `/_pagefind/` (entry and loader) are the site's own. With the pin moved
  to stack-tectonic 0.20.0 the same test fails in `build-app` with
  Turbopack's "Symlink … points out of the filesystem root" (risks ND-K).
- The repository itself: `pnpm install --frozen-lockfile`, `pnpm typecheck`,
  `pnpm lint`, `pnpm test` (8 tests), `pnpm build` green.
- Not verified: a live bootstrap against a workspace (risks ND-I).

## Verified (ND1–ND2)

- Local: `pnpm typecheck`, `pnpm lint`, `pnpm test` (5 tests), `pnpm build`
  (`next build` → Pagefind, 5 pages indexed → OpenNext bundle →
  `populateCache local`) green; `wrangler dev` over `.open-next/worker.js`:
  `/` 200 (`<title>Introduction – Nextra</title>`, the `My Project` logo, the
  Introduction text, the `Nextra Docs Template` footer, the navbar with
  About / Contact ↗ / GitHub / Discord), `/about`, `/another` (both
  counters, the `demo.js` block), `/advanced` (the folder's own page) and
  `/advanced/satori` 200, `/nope` 404, `/_pagefind/pagefind-entry.json` 200.
- CI: `Checks` green on [#2](https://github.com/sourceplane/nextra-docs/pull/2)
  (install, wire, typecheck, lint, test, build on Node 22 —
  [run](https://github.com/sourceplane/nextra-docs/actions/runs/38629100289)).
- Not verified: a live deploy. `ci.yml` is gated until the product is linked
  to an Orun workspace with a Cloudflare connection.

## Versions

| Package | Version | Why |
|---|---|---|
| next | 16.3.8 | newest inside `@opennextjs/cloudflare` 1.20.11's peer range; 16.4.x fails at worker boot (`preview-props.json` manifest) |
| @opennextjs/cloudflare | ^1.20.11 | static-assets incremental cache + `populateCache local` |
| wrangler | ^4.151.0 | compatibility_date 2026-10-01 |
| nextra, nextra-theme-docs | ^4.6.1 | the current major (App Router); the upstream's Nextra 2 needs Next 13, which the adapter cannot build |
| pagefind | ^1.5.2 | the search index, run between `next build` and the OpenNext bundle |
| zod (pnpm override, Nextra packages only) | ~4.3.6 | 4.4+ rejects `nextra-theme-docs` 4.6's `Layout` props at prerender (`risks` ND-C) |
