# nextra-docs (ND) — Implementation status

As-built ≠ intent. This file records what actually shipped, and every place
the code departed from `design.md` or from the upstream template.

| Milestone | State | PR |
|---|---|---|
| ND0 — the spec | | |
| ND1 — the docs on Workers | | |
| ND2 — ready to instantiate | | |

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

`.github/screenshot.png` and the Vercel deploy button; the upstream README
is kept verbatim as `apps/web/README.md`.
