# nextra-docs — design

## 1. What the template is

A documentation site. Five MDX pages under `pages/` (`index`, `another`,
`advanced`, `advanced/satori`, `about`), ordered and titled by
`pages/_meta.json` (three sidebar entries, an `About` navbar page and an
external `Contact ↗` navbar link), a `theme.config.tsx` that sets the logo
(`My Project`), the GitHub project link, a Discord chat link, the docs
repository base and the footer text (`Nextra Docs Template`), and a
`components/counters.tsx` counter button with a CSS module, used on the
`another` page next to a second counter defined inline in the MDX. Code
blocks carry a filename, a highlighted line and a copy button. Search is
the theme's FlexSearch index. No data source, no auth, no API.

It is Nextra 2 on Next 13 with the pages router (`next ^13.0.6`,
`nextra latest`, `nextra-theme-docs latest`, React 18, TypeScript 4.9).

## 2. The mapping (Vercel → Cloudflare)

| Vercel primitive the template uses | Here |
|---|---|
| Next.js hosting (SSG, pages router) | Cloudflare Workers + Static Assets; the Worker is `@opennextjs/cloudflare`'s output, assets bound as `ASSETS` |
| Build-time MDX compilation of `pages/` | Unchanged in substance: `next build` compiles `content/` on the build runner; every page is pre-rendered |
| Request-time render of an unknown path | Not possible on a Worker (no filesystem); `dynamicParams = false` on the catch-all makes it a 404 |
| FlexSearch index built into the client bundle | Pagefind: a static index generated after `next build` into `public/_pagefind`, bundled into the Worker's static assets and fetched by the search box |
| Deploy on push | Orun: `apps/web/component.yaml` (`cloudflare-workers-assets-turbo`) deploys `nextra-docs-web-{stage,prod}` on merge to `main` once the product is linked |

## 3. Nextra 2 → Nextra 4, file by file

`@opennextjs/cloudflare` 1.20 supports Next `>=15.5.27 <16 || >=16.3.8`;
Nextra 2 requires Next 13's pages router and its theme-config convention.
The current Nextra major (4) is App Router based. The port keeps the
template's content and behaviour and swaps the framework files:

| Upstream (Nextra 2 / Next 13) | Here (Nextra 4 / Next 16.3.8) | What it carries |
|---|---|---|
| `pages/index.mdx`, `another.mdx`, `advanced.mdx`, `advanced/satori.mdx`, `about.mdx` | `content/` with the same names | The page text, verbatim. `advanced.mdx` gains front matter `asIndexPage: true` (Nextra 4's way of making a file beside a folder of the same name the folder's own page; Nextra 2 did it implicitly). `another.mdx` imports its inline counter from a client component (next row). |
| inline `export const Counter` in `another.mdx` (uses `useState`) | `components/counter.tsx` (`'use client'`), same code | MDX is a React Server Component in Nextra 4, where hooks are not available; the page imports the component instead of defining it |
| `components/counters.tsx`, `counters.module.css` | Same files; `counters.tsx` gains the `'use client'` directive on line 1 | The external counter, unchanged otherwise |
| `pages/_meta.json` | `content/_meta.ts` (typed `MetaRecord`) | Sidebar order and titles, `About` as a navbar page, `Contact ↗` as an external navbar link. `newWindow: true` is dropped (Nextra 4's strict schema rejects it; its anchor opens external hrefs with `target="_blank"` anyway) |
| `theme.config.tsx` | `app/layout.tsx`: `<Navbar logo projectLink chatLink>`, `<Footer>`, `<Layout docsRepositoryBase pageMap>`, `metadata.title.template = '%s – Nextra'` | Logo, project link, chat link, docs repository base, footer text, and the title template Nextra 2's theme applied by default |
| `next.config.js` (`withNextra({ theme, themeConfig })`) | `next.config.mjs` (`nextra({})` around a standalone-output config) | Nextra's MDX pipeline; plus `output: "standalone"` and `outputFileTracingRoot` for OpenNext |
| (implicit page rendering) | `app/[[...mdxPath]]/page.tsx` (`generateStaticParamsFor('mdxPath')`, `importPage`, `dynamicParams = false`) and `mdx-components.tsx` | The gateway from a URL to a `content/` page; the theme's MDX components |
| FlexSearch (built into the theme) | Pagefind (`pagefind` dev dependency; `pagefind --site .next/server/app --output-path public/_pagefind` in the build script) | Full-text search over the five pages |
| `next ^13`, `react ^18`, `typescript ^4.9` | `next 16.3.8`, `react ^19.2.1`, `typescript ^5.8` | The versions OpenNext and Nextra 4 need |

Not carried: `.github/screenshot.png` (the README image) and the Vercel
deploy button; the upstream README itself is kept verbatim as
`apps/web/README.md`.

## 4. The repository

```
apps/web               the content (content/, components/) + the Nextra 4 app shell + the Workers build
  app/layout.tsx       the theme: Layout / Navbar / Footer, page map, title template
  app/[[...mdxPath]]   the gateway to content/ (pre-rendered, dynamicParams = false)
  mdx-components.tsx   the theme's MDX components
  component.yaml       Orun component: build with turbo, deploy with wrangler, smoke the home page
  wrangler.jsonc       worker name, nodejs_compat, ASSETS binding
  open-next.config.ts  static-assets incremental cache — the site binds nothing
tests/web              vitest: the content directory and _meta match the upstream layout
tooling/*              shared tsconfig / eslint / wrangler wiring renderer
intent.yaml            environments dev (verify) · stage · prod; `work:` points at specs/epics and tasks
.github/workflows      checks.yml (merge gate) · ci.yml (Orun lanes, gated by the ORUN_CI variable)
```

## 5. The build

`pnpm --filter @app/web build` runs four steps in order:

1. `next build` — compiles `content/` through Nextra, pre-renders every
   page into `.next/server/app/*.html` (standalone output, traced from the
   monorepo root).
2. `pagefind --site .next/server/app --output-path public/_pagefind` —
   indexes those HTML files into `public/_pagefind`. It must run before the
   OpenNext bundle so the index is copied into the static assets.
3. `opennextjs-cloudflare build --skipBuild --skipWranglerConfigCheck` —
   emits `.open-next/worker.js` and `.open-next/assets/` (including
   `_pagefind/`).
4. `opennextjs-cloudflare populateCache local` — writes the pre-rendered
   pages into the static-assets incremental cache
   (`.open-next/assets/cdn-cgi/_next_cache`), which the Worker reads.

Locally, `pnpm --filter @app/web preview` runs the same output under
`wrangler dev`. The search index is a build output (`_pagefind/` is
git-ignored).

## 6. Out of scope

Internationalisation, a blog theme, a custom domain, and Nextra 4 features
the template does not use (LaTeX, Mermaid, the "copy page" button, remote
MDX). A domain is the `cloudflare-domain` Terraform root the baseline
already has.

## 7. Alternative rejected

Keep Nextra 2 on Next 13 and give up OpenNext: build with
`output: "export"` (or `next-on-pages`) and serve the static export from a
plain static-assets Worker. It keeps the upstream files byte-identical,
but Next 13 is out of support, `next-on-pages` is deprecated in favour of
OpenNext, a static export drops the App Router runtime every other port in
the catalog shares, and the result would be the one repository whose
toolchain cannot be upgraded. Moving the content to the current Nextra
major keeps the content identical and the toolchain current.
