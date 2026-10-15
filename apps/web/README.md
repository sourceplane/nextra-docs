# apps/web — the docs site

A documentation site from the
[Nextra Docs Template](https://github.com/shuding/nextra-docs-template)
(MIT), on [Nextra](https://nextra.site) 4 and Next.js, running on Cloudflare
Workers + Static Assets:

- MDX pages in `content/`, ordered and titled by `content/_meta.ts`
- a sidebar, a navbar (About, an external Contact link, GitHub, Discord) and
  a table of contents per page
- code blocks with a filename, highlighted lines and a copy button
- full-text search: a [Pagefind](https://pagefind.app) index built after
  `next build` and served as static assets (`/_pagefind/`)
- dark mode

The site's name and the repository its GitHub and "Edit this page" links
point at are in `app/site.ts`.

```bash
pnpm dev        # next dev on http://localhost:3000
pnpm build      # next build + pagefind + opennextjs-cloudflare build → .open-next/
pnpm preview    # wrangler dev over the built Worker
```

How it is deployed — per environment, on merge to `main` — is the
repository's README and `component.yaml` beside this file.
