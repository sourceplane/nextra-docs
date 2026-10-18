# nextra-docs — decisions

The choices that shape this repository, one line each, with where the full
reasoning lives. Superseded decisions stay listed, marked, so the history
reads in order.

| # | Decision | Why | Source |
|---|---|---|---|
| 1 | OpenNext on Workers + Static Assets, not Pages (and not a static export) | `next-on-pages` is deprecated in favour of OpenNext, and a static export would drop the App Router runtime every other port in the catalog shares | `specs/epics/nextra-docs/README.md` (decisions locked), design.md §7 |
| 2 | Nextra 4 on Next 16.3.8, not Nextra 2 on Next 13 | `@opennextjs/cloudflare` cannot build Next 13's pages router (it needs Next ≥ 15.5.27); the five pages, the sidebar, the theme settings and the counter carry over | risk ND-A, design.md §3 |
| 3 | Every page is pre-rendered; `dynamicParams = false` | Unknown paths are a 404 and the Worker serves pages from the static-assets cache | risk ND-F |
| 4 | Search is Pagefind, indexed between `next build` and the OpenNext bundle, in the job's own tree | The index must ship as static assets the Worker serves | risks ND-E, ND-N |
| 5 | No infra root: the site binds nothing | Nothing to provision; `infra/` and `packages/` stay as empty discovery roots | README (decisions locked), IMPLEMENTATION-STATUS (ND3) |
| 6 | The site's name and repository are one seam, `apps/web/app/site.ts`; the upstream credit is protected from the rename | The rename's slug rule would have rewritten `nextra-docs-template` | risk ND-M |
| 7 | ~~Three phases: `01-scaffold`, `02-site`, `03-docs`~~ (`baseline-v1`) — superseded by #8 | — | IMPLEMENTATION-STATUS, "One landing (ND4)" |
| 8 | One landing (`01-product`) then the record (`03-docs`); each bootstrap pull request checked by `plan` alone | A landing has a fixed cost; the convergence on main builds, deploys and smoke-tests the site for real (cirrus-baseline baseline-v22, portfolio-starter-kit PK-6) | IMPLEMENTATION-STATUS (ND4) |
| 9 | `ci.yml` plans nothing while `intent.yaml` names `ws_CHANGE_ME`; `checks.yml` runs on pull requests only | A bootstrap cannot set a repository variable; a push to main must start `ci.yml` alone | IMPLEMENTATION-STATUS (ND3), risk ND-L |
| 10 | stack-tectonic 0.19.0, not 0.20.0 | 0.20.0's lane-shared install is refused by Turbopack | risk ND-K |
| 11 | orun is pinned only where it runs (the `orun-action` `version:` in each workflow); no kiox | `kiox.yaml` pinned a version (v2.15.0) nothing ran | IMPLEMENTATION-STATUS (ND5) |
| 12 | Component docs are generated from the manifests and checked in CI | A hand-written copy of the component's facts drifts silently | `tooling/catalog/gen-component-docs.py` |
