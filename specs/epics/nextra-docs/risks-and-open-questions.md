# nextra-docs — risks and open questions

## ND-A — The upstream framework cannot be built by the adapter (RESOLVED)

The template is Nextra 2 on Next 13's pages router; `@opennextjs/cloudflare`
1.20 supports Next `>=15.5.27 <16 || >=16.3.8`. Decision: port the content
to Nextra 4 (App Router) on Next 16.3.8 rather than keep Nextra 2 without
OpenNext (`design.md` §7). The page text, the sidebar order, the theme
settings and the counter component are preserved; the framework files are
replaced, file by file (`design.md` §3).

## ND-B — OpenNext and Next.js version drift (RISK, mitigated)

The port pins `next 16.3.8` (the newest inside the adapter's peer range;
16.4.x fails at worker boot on 1.20.11) and `@opennextjs/cloudflare
^1.20.11` so a `pnpm install` reproduces the verified build. Bumping Next
is a deliberate PR that re-runs the build and the preview.

## ND-C — Nextra's zod dependency drifts under it (RESOLVED)

`nextra-theme-docs` 4.6 validates its `Layout` props with zod and relies
on `z.custom()` accepting a missing key (it strips `children` before the
parse). zod 4.4.0 changed that: with pnpm's newest match for Nextra's
`^4.1.12` (4.6.x) every page fails at prerender with "expected nonoptional,
received undefined → at children". Decision: a pnpm override scoped to the
two Nextra packages pins their zod to `~4.3.6` (the newest that works);
wrangler and OpenNext keep their own. Drop the override when Nextra marks
the field optional.

## ND-D — Interactive components inside MDX (RESOLVED)

Nextra 4 renders MDX as React Server Components; the upstream `another.mdx`
defines a `useState` counter inline, which cannot run there. Decision: the
same code lives in `components/counter.tsx` with `'use client'` and the
page imports it; `components/counters.tsx` gains the directive too. The
rendered page is the same two buttons.

## ND-E — The search index must ship as static assets (RESOLVED)

Pagefind indexes the HTML `next build` writes, so it has to run after
`next build` and before `opennextjs-cloudflare build` (which copies
`public/` into `.open-next/assets`). The `build` script runs the four steps
in that order; `_pagefind/` is git-ignored as a build output.

## ND-F — Unknown paths (RESOLVED)

A Worker has no filesystem at request time. `dynamicParams = false` on the
`[[...mdxPath]]` gateway pre-renders every page in the page map and makes
anything else a 404 — the same result Nextra 2's static export gave.

## ND-G — Git timestamps at build time (ACCEPTED)

Nextra reads each page's last-modified date from `git log`; on a shallow
checkout or an uncommitted tree it warns and omits the date. CI checks out
one commit, so "last updated" shows that commit's date. No build failure.

## ND-H — Worker size (ACCEPTED)

The Worker is small (the pages are pre-rendered and served from the
static-assets cache); the Pagefind index is ~700 KB of static assets. Well
under the limits.
