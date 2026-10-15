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
  app/site.ts          the site's name and repository — the seam the baseline renames (§8)
  app/[[...mdxPath]]   the gateway to content/ (pre-rendered, dynamicParams = false)
  mdx-components.tsx   the theme's MDX components
  component.yaml       Orun component: build with turbo, deploy with wrangler, smoke the home page
  wrangler.jsonc       worker name, nodejs_compat, ASSETS binding
  open-next.config.ts  static-assets incremental cache — the site binds nothing
tests/web              vitest: the content directory and _meta match the upstream layout; the identity seam
tooling/*              shared tsconfig / eslint / wrangler wiring renderer
intent.yaml            environments dev (verify) · stage · prod; `work:` points at specs/epics and tasks
.github/workflows      checks.yml (every PR) · ci.yml (Orun lanes; plans nothing while the workspace is ws_CHANGE_ME)
                       · baseline.yml and tag.yml (the baseline's own, never shipped — §8)
```

The baseline around it (§8): `blueprint.yaml`, `repo-blueprint.yaml`,
`.baseline/`, `tooling/rebrand`, `tooling/bootstrap`, `hooks/`, `ai/context/`,
`docs/phases/`, `BOOTSTRAP.md`, `testing/`.

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

Internationalisation, a blog theme, a custom-domain component, and Nextra 4
features the template does not use (LaTeX, Mermaid, the "copy page" button,
remote MDX). A domain is attached to the Worker by its owner (§8: the
brokered deploy token carries no zone permissions); nothing in the build
depends on the origin, because every link the site renders is relative.

## 7. Alternative rejected

Keep Nextra 2 on Next 13 and give up OpenNext: build with
`output: "export"` (or `next-on-pages`) and serve the static export from a
plain static-assets Worker. It keeps the upstream files byte-identical,
but Next 13 is out of support, `next-on-pages` is deprecated in favour of
OpenNext, a static export drops the App Router runtime every other port in
the catalog shares, and the result would be the one repository whose
toolchain cannot be upgraded. Moving the content to the current Nextra
major keeps the content identical and the toolchain current.

## 8. The baseline (ND3)

The repository instantiates new docs sites the way
[cirrus-baseline](https://github.com/sourceplane/cirrus-baseline) instantiates
products, and exactly the way `portfolio-starter-kit` (its `baseline-v2`) does
for a portfolio: a console card (`blueprint.yaml`) the platform renders, a
build document (`repo-blueprint.yaml`) `orun new` runs, and a rename engine
that makes the copy somebody else's.

| Cirrus | Here | Why the difference |
|---|---|---|
| six phases (scaffold, foundation + data plane, workers, edge + console, domain, docs) | three: `01-scaffold`, `02-site`, `03-docs` | one component deploys; no data plane, no fleet, no bindings |
| `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_D1_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | `CLOUDFLARE_API_TOKEN` (`workers-deploy`), `CLOUDFLARE_ACCOUNT_ID` | no D1 |
| `07-domain` (parked component) | no domain phase, and no `SITE_URL` | `workers-deploy` has no DNS or zone scope; and unlike the portfolio, a Nextra site bakes no absolute link (no sitemap, feed or Open Graph image), so nothing needs the origin |
| task contracts in `tasks/` | `.baseline/tasks/` | `tasks/` is this repository's own work tree (`intent.yaml` `work:`), where an unkeyed contract is an error |
| ships its own README | ships `.baseline/product/README.md` as the site's README | this README is about the baseline; a site's owner needs the site's |
| — | `work-tree.mjs` strips `work:` from the site's intent | a site has no `specs/` or `tasks/` |
| stack-tectonic 0.20.0 (lane-scoped install) | 0.19.0 (the job installs in its own tree) | Next 16's Turbopack cannot build through the lane's symlinked `node_modules` (risks ND-K) |
| one push workflow (`ci.yml`) | `checks.yml` on pull requests only | `orun.run/watch@v1` takes the newest run for a commit from any workflow (risks ND-L) |
| rebrand rules for a SaaS (console prefix, SDK class, CLI bin, API host) | rules for a site: the source link (owner + repo), the `SITE_NAME` seam, the domain, the subdomain, Worker names, secret refs, the repo slug; the upstream template's repository protected | the identity this tree actually carries (risks ND-M) |

**Identity in the app** is two literals in `apps/web/app/site.ts`: `SITE_NAME`
(the navbar logo, the default title and the `%s – <name>` template, the
footer) and `SOURCE_URL` (the navbar's GitHub link; `DOCS_REPOSITORY_BASE`,
built on it, is where "Edit this page" and the feedback link point).
`app/layout.tsx` spells neither. The rename writes the site name with
`JSON.stringify`, so any name the card's pattern admits — apostrophes and
ampersands included — stays a valid string; React escapes it in the HTML.

**The smoke reads the site, not its name.** It was `grep 'My Project'`, which
a renamed site fails (and an escaped `&` or `'` would too). It now requires
the docs theme's navbar on `/` and the Pagefind index at
`/_pagefind/pagefind-entry.json` — the two things every Nextra site built
from this has, and the second the one a broken build most quietly loses.

**The site's CI is on from its first commit.** `ci.yml` used to wait for an
`ORUN_CI` repository variable, which a bootstrap has no way to set. It now
plans nothing only while `intent.yaml` names the placeholder `ws_CHANGE_ME`,
which this repository carries and no site does (the scaffold writes the
site's workspace, or `ws_SET_ME`, which fails loudly).

**Testing without the platform.** `testing/lib/bootstrap.sh` places every
phase and runs the blueprint's own `run:` hooks, read out of the document, so
the whole bootstrap short of the platform's typed actions runs in CI on every
pull request; `testing/e2e.test.sh` then builds the produced site in a job
tree staged the way orun stages it (`testing/lib/stage-job.py`, with the
install layout the pinned composition plans), checks the build ran on
Turbopack and wrote its own search index over every page, dry-deploys it,
serves it with `wrangler dev` and runs the component's own smoke against it.
