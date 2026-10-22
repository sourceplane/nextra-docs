# nextra-docs — implementation plan

Milestones land in order; each task is one pull request on an
`orun/ND-n-<slug>` branch with an `Orun-Task: ND-n` trailer.

## ND0 — the spec ✅

This doc set, `epic.yaml` and the task contracts, merged to `main`.

**Done when**
- the five documents and `epic.yaml` are on `main`
- `tasks/ND-1.TaskContract.yaml`, `ND-2`, `ND-3` exist (ND-4 joined with ND3)

## ND1 — the docs on Workers ✅

`apps/web` is the upstream content on Nextra 4 with the Workers build
around it; `tests/web` pins the content directory and `_meta` to the
upstream layout.

**Done when**
- `pnpm install && pnpm typecheck && pnpm lint && pnpm test && pnpm build` is green locally and in `Checks`
- `.open-next/worker.js`, `.open-next/assets/` and `.open-next/assets/_pagefind/` exist after the build
- `wrangler dev` (via `pnpm --filter @app/web preview`) answers `/` with the Introduction and the `My Project` logo, `/about`, `/another`, `/advanced` and `/advanced/satori` with their text, `/nope` with a 404, and `/_pagefind/pagefind-entry.json` with the index

## ND2 — ready to instantiate ✅

The README explains the port and how to run, test, preview and deploy it;
`IMPLEMENTATION-STATUS.md` records what shipped and every departure.

**Done when**
- the README's quick start works from a fresh clone
- the status file names the PRs and every Nextra 2 → 4 departure

## ND3 — a baseline (ND-4) ✅

`blueprint.yaml`, `repo-blueprint.yaml`, `.baseline/` (identity, task
contracts, the site's README), `tooling/rebrand`, `tooling/bootstrap`,
`hooks/render-deployment-docs.sh`, `ai/context/`, `docs/phases/`,
`BOOTSTRAP.md`, `testing/`, `baseline.yml` and `tag.yml`, the
`apps/web/app/site.ts` seam (design §8). Ported from `portfolio-starter-kit`
at `baseline-v2`, with what its first live bootstrap taught already in:
stack-tectonic 0.19.0, `checks.yml` on pull requests only, the end-to-end
build in a staged job tree.

**Done when**
- orun at the bootstrap floor (v2.58.11) and at the lane pin (v2.78.4) reads
  `repo-blueprint.yaml`, and `testing/manifest.test.sh` holds the card to it
- `Baseline CI` is green: the contract tests, the leak gate, the offline
  bootstrap (`testing/placement.test.sh`) and the end-to-end tier
  (`testing/e2e.test.sh`) — whose staged build runs on Turbopack and ships
  its own Pagefind index
- the status file records what is proven offline and what only a live
  bootstrap can prove

## ND4 — one landing (ND-5) ✅

The site in one landing, the way cirrus-baseline's baseline-v22 builds its
product and portfolio-starter-kit's PK-6 followed: `repo-blueprint.yaml`
places every module in `01-product` and records it in `03-docs` (hooks
only); the card's programme names the same two; each bootstrap pull request
is checked by `plan` alone (`ci.yml` skips the lanes and `checks.yml` its
job on `orun/BASE-…` branches); the brokered secrets are minted in
`01-product`'s `post`, after `repo` and `link`.

**Done when**
- `testing/phases.test.sh` holds the two phases and their hooks, and the
  offline bootstrap and the e2e tier pass over one landing
- Baseline CI is green
- a site bootstrapped from the next tag is live faster than baseline-v1's
  measured 8m15s — not yet: `baseline-v2` is the first tag that carries ND4,
  and no site has been bootstrapped from it (risk ND-I)

## ND5 — the cirrus standard (ND-6) ✅

Bring the baseline to cirrus-baseline's standard, with nothing about the
site itself changing.

- **No kiox.** `kiox.yaml`/`kiox.lock` pinned an orun (v2.15.0) that nothing
  ran: every workflow installs orun itself through `orun-action` with its own
  `version:`. The files, their two modules, the rebrand's skip entry and the
  01-product phase document's mention go.
- **Component docs.** `tooling/catalog/gen-component-docs.py` writes each
  component's `docs/overview.md`, `docs/architecture.md` and `docs/runbook.md`
  from what the component declares, as cirrus-baseline's do; the pages ship
  with the component. Baseline CI runs it with `--check`.
- **The context pack.** `ai/context/current.md`, `decisions.md` and
  `open-risks.md` beside the two pages a site ships with — this
  repository's own, so no module places them.
- **Status that agrees with the tags and the live record.** ND4 is shipped
  (untagged until `baseline-v2`); `baseline-v1` went live on 2026-10-15, so
  risk ND-I is now about the one-landing shape.
- **The subdomain from the Cloudflare connection (ND-7).** The card's
  `subdomain` input declares `from: connection.cloudflare.workersSubdomain`,
  as cirrus-baseline's does since baseline-v23: the bootstrap door fills it
  from the connection the build is bound to, so the console asks for nothing
  a typo could get wrong. `testing/manifest.test.sh` takes cirrus-baseline's
  rule, which requires the provider in `spec.requires.integrations`.

**Done when**
- nothing outside this milestone's own record (its specs, task and context
  pages) names kiox, and the leak gate and the offline bootstrap pass
  without the two modules
- the docs check is green in Baseline CI
- this file, the status file and `epic.yaml` agree

## ND6 — the domain is set later (ND-8) ✅

**Done when** the console card asks for no domain; `productdomain` is an
optional build input, empty by default; a site built without one is branded
with the reserved placeholder `<reponame>.example.com` where the domain goes
(`BASE_DOMAIN` in `intent.yaml`) and its README says how an owner sets the
real one; Baseline CI places, leak-checks and plans a site built with no
domain. Shipped in `baseline-v3`.

## After ND3 (outside this repository)

1. Cut `baseline-v1` with `tag.yml` from the merged `main` — done.
2. Register the row in orun-cloud's `infra/baselines-registry/baselines.yaml`
   (unlisted) with the card vendored at the tag.
3. Bootstrap one site from the tag against a workspace; record its timings;
   then flip the row to public with a page on orunbase.com. — The bootstrap
   ran on 2026-10-15 (8m15s, live on stage and prod; IMPLEMENTATION-STATUS).

## Sequencing note

ND1 needs nothing but ND0's contracts. ND2 is documentation over ND1's
verified build and can land the same day; ND3 packages ND1's site as a
baseline. Deploying to a Cloudflare account is not a milestone here: it is
the Orun lane (`ci.yml`), which plans as soon as `intent.yaml` names a real
workspace.
