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

In an Orun lane the build runs in the job tree orun stages under the
checkout's `.orun/runs/…/work` — inside the repository's git root, but
untracked there — so `git log` finds no history for any page: Nextra warns
(`Failed to get the last modified timestamp from Git`) and the deployed pages
carry no "Last updated" line at all. Seen in a staged build (ND3); a local
`pnpm build` in a clone still shows the dates. Accepted: the date is
cosmetic, and the build does not fail.

## ND-H — Worker size (ACCEPTED)

The Worker is small (the pages are pre-rendered and served from the
static-assets cache); the Pagefind index is ~700 KB of static assets. Well
under the limits.

## ND-I — The one-landing shape is not yet proven live (OPEN)

`baseline-v1` was: a console bootstrap of it (ND3's three phases,
`01-scaffold`, `02-site`, `03-docs`) went live on stage and prod on
2026-10-15 — `nextra-live`, `bst_PW76WBTK`, 8m15s end to end
(IMPLEMENTATION-STATUS, "One landing (ND4)"). What `main` builds now is
ND4's shape — the whole site in one landing (`01-product`), then the record
(`03-docs`), each bootstrap pull request checked by `plan` alone — and that
is proven offline on every pull request: the card against the build, the
blueprint read by the pinned orun, the leak gate, the offline bootstrap with
the blueprint's own hooks, the site's own plan for the 01-product merge, and
the produced site built in a staged job tree, dry-deployed, served and
smoke-tested. It has not been bootstrapped live, and no tag carries it yet.
Closes with one bootstrap from the next tag, whose timing replaces the
6-minute estimate.

(Updated in ND5. Until then this entry read "No live bootstrap yet" and
cited the 02-site merge, a phase ND4 removed.)

## ND-J — A custom domain is the owner's step (ACCEPTED)

Attaching a domain to a Worker needs zone-level permissions. The platform
brokers `workers-deploy` (Workers Scripts, KV, account read — no DNS) and
`dns-edit` only with zone ids, which a build does not have. Rather than ship a
parked component (Cirrus's `07-domain` is one), the site's README says how to
attach the domain. Unlike the portfolio baseline there is no `SITE_URL`: the
docs site renders no absolute link to its own origin (no sitemap, feed or
Open Graph image; the GitHub links are absolute but origin-free), so the
build needs no origin and a domain needs no redeploy.

## ND-K — Turbopack cannot build through a lane-shared install (RESOLVED before the first tag)

`portfolio-starter-kit`'s first live bootstrap (from its `baseline-v1`)
failed both deploy lanes in `build-app`:

```
Symlink [project]/apps/web/node_modules/next is invalid, it points out of the filesystem root
```

stack-tectonic 0.20.0 marks the workspace install `scope: lane`; orun runs it
once in the source checkout and stages every job's tree with its top-level
`node_modules` as a symlink to the source's (orun
`internal/runner/workspace.go`, `materializeTree`). Next 16 builds with
Turbopack, which refuses a dependency that resolves outside its root. This
site is the same shape — Next 16.3.8, Turbopack, `outputFileTracingRoot` at
the monorepo root — so it takes the same fix from its first tag: pin
stack-tectonic **0.19.0**, where the job installs inside its own staged tree;
with one job per lane the shared install saved nothing. Not `next build
--webpack`, and not `turbopack.root`: the root must equal
`outputFileTracingRoot`, and moving that reshapes OpenNext's standalone
output.

Reproduced here, not assumed: `testing/e2e.test.sh` stages the job as orun
does (`testing/lib/stage-job.py`) with the install layout the pinned
composition plans. With the pin moved to 0.20.0 it fails in `build-app` with
the error above; on 0.19.0 it is green. It also requires the staged build to
have run on Turbopack, so a silent switch to webpack is a red test, not a
different build.

## ND-L — The convergence watch reads the newest run from any workflow (RESOLVED before the first tag)

`orun.run/watch@v1` with `sha:` takes the newest workflow run for the merge
commit from ANY workflow (`RunForCommit`, `per_page=1`). The portfolio's
first live bootstrap watched `checks.yml` go green on the push to main while
`ci.yml`'s deploy lanes had failed. Here `checks.yml` runs on pull requests
(and by hand) only, so a push to main starts `ci.yml` alone;
`testing/coverage.test.sh` fails if a shipped workflow other than `ci.yml`
runs on push.

## ND-M — The upstream template's name begins with this baseline's slug (RESOLVED)

The site credits its upstream, `github.com/shuding/nextra-docs-template`
(MIT), in its README and `apps/web/README.md`. The rename's repo-slug rule
(`\bnextra-docs\b`) matches the head of `nextra-docs-template` and would have
turned the credit into a link to `<reponame>-template`, and the leftover
sweep would have flagged it as residue. `tooling/rebrand/rebrand.mjs`
protects that one repository path the way it protects org-owned identity;
`testing/rebrand.test.sh` holds both directions (the credit survives, any
other `nextra-docs-template` is still residue). The layout's GitHub link and
docs base, which pointed at the upstream, now point at the site's own
repository through `app/site.ts`.

## ND-N — The search index must be built in the job's own tree (RESOLVED)

Pagefind runs over `.next/server/app` inside `apps/web`'s build script, and
the OpenNext bundle copies `public/_pagefind` into the assets. In a lane both
happen in orun's staged job tree, which starts with no build output at all.
The end-to-end tier deletes the source tree's index before staging, so the
index it finds in the staged `.open-next/assets/_pagefind/` can only be the
staged build's own, and requires it to hold every page in `content/`. The
deploy's smoke and the `03-docs` record both read
`/_pagefind/pagefind-entry.json`. `_pagefind` is in the blueprint's `ignore`
list, so an operator's local index never ships.
