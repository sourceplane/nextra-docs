# nextra-docs — implementation plan

Milestones land in order; each task is one pull request on an
`orun/ND-n-<slug>` branch with an `Orun-Task: ND-n` trailer.

## ND0 — the spec

This doc set, `epic.yaml` and the task contracts, merged to `main`.

**Done when**
- the five documents and `epic.yaml` are on `main`
- `tasks/ND-1.TaskContract.yaml`, `ND-2`, `ND-3` exist

## ND1 — the docs on Workers

`apps/web` is the upstream content on Nextra 4 with the Workers build
around it; `tests/web` pins the content directory and `_meta` to the
upstream layout.

**Done when**
- `pnpm install && pnpm typecheck && pnpm lint && pnpm test && pnpm build` is green locally and in `Checks`
- `.open-next/worker.js`, `.open-next/assets/` and `.open-next/assets/_pagefind/` exist after the build
- `wrangler dev` (via `pnpm --filter @app/web preview`) answers `/` with the Introduction and the `My Project` logo, `/about`, `/another`, `/advanced` and `/advanced/satori` with their text, `/nope` with a 404, and `/_pagefind/pagefind-entry.json` with the index

## ND2 — ready to instantiate

The README explains the port and how to run, test, preview and deploy it;
`IMPLEMENTATION-STATUS.md` records what shipped and every departure.

**Done when**
- the README's quick start works from a fresh clone
- the status file names the PRs and every Nextra 2 → 4 departure

## Sequencing note

ND1 needs nothing but ND0's contracts. ND2 is documentation over ND1's
verified build and can land the same day. Deploying to a Cloudflare account
is not a milestone here: it is the Orun lane (`ci.yml`) that turns on when
`intent.yaml`'s workspace is set and the `ORUN_CI` variable is `true`.
