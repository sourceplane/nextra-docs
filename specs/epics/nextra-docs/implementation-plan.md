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

## ND3 — a baseline 🟡

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

## After ND3 (outside this repository)

1. Cut `baseline-v1` with `tag.yml` from the merged `main`.
2. Register the row in orun-cloud's `infra/baselines-registry/baselines.yaml`
   (unlisted) with the card vendored at the tag.
3. Bootstrap one site from the tag against a workspace; record its timings;
   then flip the row to public with a page on orunbase.com.

## Sequencing note

ND1 needs nothing but ND0's contracts. ND2 is documentation over ND1's
verified build and can land the same day; ND3 packages ND1's site as a
baseline. Deploying to a Cloudflare account is not a milestone here: it is
the Orun lane (`ci.yml`), which plans as soon as `intent.yaml` names a real
workspace.
