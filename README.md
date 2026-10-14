# nextra-docs

Vercel's [Nextra Docs Starter Kit](https://github.com/shuding/nextra-docs-template)
— five MDX pages, a sidebar ordered by `_meta`, an About page and an external
Contact link in the navbar, an interactive counter, full-text search —
running on **Cloudflare Workers + Static Assets** through
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare), inside the
repository conventions of the
[Cirrus baseline](https://github.com/sourceplane/cirrus-baseline): an
[Orun](https://github.com/sourceplane/orun) intent, one component per
deployable, a credential-free check lane as the merge gate, and an Orun lane
that turns on once the product is linked to a workspace.

The template's content is the content. The upstream is Nextra 2 on Next 13's
pages router, which the OpenNext adapter cannot build, so the same pages,
sidebar, theme settings and counter component are expressed through
[Nextra 4](https://nextra.site) on the App Router (a `content/` directory,
a `[[...mdxPath]]` gateway, `_meta.ts`, Pagefind search). What the port adds
is the Workers build, the monorepo wrapper, a test package, and the deploy
contract. See [`specs/epics/nextra-docs`](specs/epics/nextra-docs/README.md)
for the design (including the Nextra 2 → 4 mapping, file by file), the
milestones and the as-built status.

## What is here

| Surface | Where |
|---|---|
| The pages — Introduction, Another Page, Advanced, Satori, About | `apps/web/content` |
| Sidebar order, navbar pages and the external Contact link | `apps/web/content/_meta.ts` |
| The theme — logo, project and chat links, footer, title template | `apps/web/app/layout.tsx` |
| The gateway from a URL to a content page | `apps/web/app/[[...mdxPath]]/page.tsx`, `apps/web/mdx-components.tsx` |
| The counter components (one inline upstream, one external) | `apps/web/components/counter.tsx`, `apps/web/components/counters.tsx` |
| Workers build and deploy contract | `apps/web/next.config.mjs`, `apps/web/open-next.config.ts`, `apps/web/wrangler.jsonc`, `apps/web/component.yaml` |
| Tests | `tests/web` (vitest) |

## Getting started

```bash
pnpm install
pnpm typecheck
pnpm lint
pnpm test
pnpm build            # next build + pagefind + opennextjs-cloudflare build → apps/web/.open-next
```

Develop with Next's dev server, or preview the real Worker output locally:

```bash
pnpm --filter @app/web dev        # http://localhost:3000 (no search index until a build has run)
pnpm --filter @app/web preview    # wrangler dev over .open-next/worker.js
```

Add a page by dropping an `.mdx` file into `apps/web/content/` and naming it
in `content/_meta.ts` (or leave it out of `_meta` to sort it after the named
ones); it is pre-rendered and indexed at build time.

## How it maps to Vercel

| Vercel | Here |
|---|---|
| Next.js hosting (SSG) | Cloudflare Worker (`.open-next/worker.js`) + Static Assets (`ASSETS` binding); the pre-rendered pages are served from the static-assets incremental cache |
| Nextra 2 on Next 13 (pages router) | Nextra 4 on Next 16.3.8 (App Router); same content, same sidebar, same theme settings |
| FlexSearch index in the client bundle | Pagefind index built after `next build` into `public/_pagefind`, shipped as static assets |
| Request-time render of an unknown path | Every page is pre-rendered (`dynamicParams = false`, so an unknown path is a 404 — a Worker has no filesystem at request time) |
| Deploy on push | Orun deploys `nextra-docs-web-{stage,prod}` on merge to `main` (`apps/web/component.yaml`) |

## Deploying

`.github/workflows/checks.yml` runs install, typecheck, lint, test and build on
every push and pull request. `ci.yml` is the Orun deployment pipeline: set
`execution.state.workspace` in `intent.yaml` to this product's Orun workspace
(`orun cloud link`), connect a Cloudflare account to that workspace, and set
the `ORUN_CI` repository variable to `true`. From then on a merge to `main`
deploys the Worker to `stage`, then `prod`.
