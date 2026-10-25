# nextra-docs

A documentation site — MDX pages, a sidebar and navbar ordered by `_meta`,
code blocks with copy buttons, dark mode and full-text search — built with
[Nextra](https://nextra.site) 4 on Next.js and running on **Cloudflare
Workers + Static Assets** through
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare). It started
from the [Nextra Docs Template](https://github.com/shuding/nextra-docs-template)
(MIT).

## Live deployment

<!-- 03-docs:begin -->
Not recorded yet. The bootstrap's last phase writes the live URLs, the
workspace and the secrets the site uses into
[ai/context/deployment.md](ai/context/deployment.md); how the site deploys
and how to operate it is in
[ai/context/operations.md](ai/context/operations.md).
<!-- 03-docs:end -->

## What is here

| Surface | Where |
|---|---|
| The site's name and the repository its GitHub and "Edit this page" links point at | `apps/web/app/site.ts` |
| The pages (MDX) | `apps/web/content` |
| Sidebar order, navbar pages and external links | `apps/web/content/_meta.ts` |
| The theme — logo, links, footer, title template | `apps/web/app/layout.tsx` |
| The gateway from a URL to a content page | `apps/web/app/[[...mdxPath]]/page.tsx`, `apps/web/mdx-components.tsx` |
| React components used from MDX | `apps/web/components` |
| Workers build and deploy contract | `apps/web/next.config.mjs`, `open-next.config.ts`, `wrangler.jsonc`, `component.yaml` |
| Tests | `tests/web` (vitest) |

## Getting started

```bash
pnpm install
pnpm typecheck
pnpm lint
pnpm test
pnpm build            # next build + pagefind + opennextjs-cloudflare build → apps/web/.open-next
```

```bash
pnpm --filter @app/web dev        # http://localhost:3000 (no search index until a build has run)
pnpm --filter @app/web preview    # wrangler dev over the built Worker
```

Write a page by dropping an `.mdx` file into `apps/web/content/` and naming
it in `content/_meta.ts` (or leave it out of `_meta` to sort it after the
named ones); every page is pre-rendered and indexed for search at build
time, and a path that is not a page is a 404. Make the site yours in
`apps/web/content/` (the pages), `content/_meta.ts` (the sidebar and navbar)
and `apps/web/app/site.ts` (its name and repository).

## How it deploys

Merges to `main` converge through [Orun](https://github.com/sourceplane/orun):
`.github/workflows/ci.yml` plans the changed components and runs each lane
against the workspace in `intent.yaml`. The site deploys to `stage`, then to
`prod` once stage has converged on the same commit; `dev` only verifies. The
Worker is `nextra-docs-web-<env>` on your account's workers.dev subdomain,
and every deploy is smoke-tested over HTTP: the home page must render and the
search index must be served. A pull request runs the same pipeline's verify
lanes: the site built and dry-deployed for each environment, with nothing
deployed. They do not lint or run the tests, so run `pnpm typecheck`,
`pnpm lint` and `pnpm test` before you push. (A push to `main` builds,
deploys and smoke-tests.)

The pipeline holds one credential, GitHub's own `GITHUB_TOKEN`. The
Cloudflare token and account id are brokered per run from the workspace's
Cloudflare connection; nothing provider-shaped is stored in the repository
or in GitHub.

## Custom domain

The site answers on workers.dev from its first deploy. To serve it on your
own domain, add the domain to the Cloudflare account the site deploys into
and attach it to the Worker (dashboard → Workers & Pages →
`nextra-docs-web-prod` → Settings → Domains & Routes → Add → Custom domain).
Do the same for stage with a subdomain if you want one. Nothing in the build
depends on the origin — every link the site renders is relative — so there
is nothing to redeploy. The repository names the domain in one place,
`BASE_DOMAIN` in `intent.yaml` (dev, stage and prod), which the site was born
with as the reserved placeholder `nextra-docs.example.com`. Replace it with
your domain in the same change that records it.
