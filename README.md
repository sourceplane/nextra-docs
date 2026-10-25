# nextra-docs

Vercel's [Nextra Docs Starter Kit](https://github.com/shuding/nextra-docs-template)
— five MDX pages, a sidebar ordered by `_meta`, an About page and an external
Contact link in the navbar, an interactive counter, full-text search —
running on **Cloudflare Workers + Static Assets** through
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare), and packaged
as an **Orun baseline**: one command takes a new docs site from nothing to
live on stage and prod, in its own repository, under its own name.

The template's content is the content. The upstream is Nextra 2 on Next 13's
pages router, which the OpenNext adapter cannot build, so the same pages,
sidebar, theme settings and counter component are expressed through
[Nextra 4](https://nextra.site) on the App Router (a `content/` directory,
a `[[...mdxPath]]` gateway, `_meta.ts`, Pagefind search). What the port adds
is the Workers build, the monorepo wrapper, a test package, and the deploy
contract. What the baseline adds is everything needed to make a copy of it
somebody else's — built the way
[cirrus-baseline](https://github.com/sourceplane/cirrus-baseline) is, with
the repository conventions it shares: an [Orun](https://github.com/sourceplane/orun)
intent, one component per deployable, credential-free checks on every pull
request, and an Orun pipeline that deploys on merge. See
[`specs/epics/nextra-docs`](specs/epics/nextra-docs/README.md) for the design
(including the Nextra 2 → 4 mapping, file by file), the milestones and the
as-built status.

## Instantiating a site

```bash
git clone --depth 1 --branch <baseline-tag> https://github.com/sourceplane/nextra-docs
cd nextra-docs
orun new --blueprint repo-blueprint.yaml --out ~/sites/acme-docs --run-hooks --resume \
  --set reponame=acme-docs --set productname="Acme Docs" \
  --set githuborg=acme-inc --set subdomain=<workers-dev-subdomain>
```

Or, once the platform's registry lists it, from the Orun console (Baselines →
`nextra-docs` → Build). Two phases — `01-product` (the repository created,
then the whole site in one pull request, deployed to stage and prod and
smoke-tested) and `03-docs` (the live deployment recorded) — each landing one
pull request in the new repository. **[BOOTSTRAP.md](BOOTSTRAP.md)** is the
operator guide; [docs/phases/](docs/phases/README.md) has a page per phase.

The new repository receives the **site only** — the app, its tests, its CI,
its tooling, a README of its own and its operating contract — renamed
throughout to the site's name, repository and Cloudflare Worker. None of this
repository's machinery ships.

| What makes it a baseline | Where |
|---|---|
| The console card (inputs, secrets, programme) | `blueprint.yaml` |
| The build document (modules, phases, hooks) | `repo-blueprint.yaml` |
| This tree's identity, and the bootstrap's task contracts | `.baseline/` |
| The rename engine | `tooling/rebrand/rebrand.mjs` |
| The bootstrap's helpers (deferrals, redeploy marker, work-tree strip) | `tooling/bootstrap/` |
| The deployment-record renderer | `hooks/render-deployment-docs.sh` |
| The site's README and context pack | `.baseline/product/README.md`, `ai/context/` |
| The baseline's tests: contract, leak, offline bootstrap, end to end | `testing/`, `.github/workflows/baseline.yml` |
| Cutting a `baseline-vN` tag | `.github/workflows/tag.yml` |

## What is here (the site)

| Surface | Where |
|---|---|
| The site's name and the repository its GitHub and "Edit this page" links point at | `apps/web/app/site.ts` |
| The pages — Introduction, Another Page, Advanced, Satori, About | `apps/web/content` |
| Sidebar order, navbar pages and the external Contact link | `apps/web/content/_meta.ts` |
| The theme — logo, project and chat links, footer, title template (reading `site.ts`) | `apps/web/app/layout.tsx` |
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
| Deploy on push | Orun deploys `<repo>-web-{stage,prod}` on merge to `main` (`apps/web/component.yaml`), smoke-testing the home page and the search index |
| "Deploy to Vercel" (clone the template) | `orun new --blueprint repo-blueprint.yaml` — a new repository, branded, deployed |

## CI

| Workflow | What it runs | Ships to a site |
|---|---|---|
| `ci.yml` | the Orun pipeline, and the only workflow a site carries: `orun plan --changed`, then one job per lane. A pull request runs the verify lanes (the site built and dry-deployed per environment; the tests' `quick-check` lane installs and checks the package, it does not run them), except the bootstrap's own landings (`orun/BASE-*`), where `plan` alone is the check; a merge deploys stage → prod. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does | yes |
| `baseline.yml` | the baseline's own tiers: contract tests, the blueprint read by the pinned orun, the leak gate, the offline bootstrap, the site built in a staged job tree, dry-deployed and served | no |
| `tag.yml` | cuts a `baseline-vN` tag (manual) | no |
