# nextra-docs — where this repository stands

The entry page for anyone (or any agent) picking this repository up. It is
this repository's own state and does not ship to a site built from it; the
two pages that do are [operations.md](operations.md) and
[deployment.md](deployment.md).

## What it is

Vercel's Nextra Docs Starter Kit — five MDX pages, a sidebar, search — moved
from Nextra 2 to Nextra 4 and run on Cloudflare Workers + Static Assets
through OpenNext, packaged as an Orun baseline: `orun new --blueprint
repo-blueprint.yaml` builds a new docs site in its own repository and takes
it to live on stage and prod in one landing (`01-product`), then records
what went live (`03-docs`).

## Release

| | |
|---|---|
| Latest tag | `baseline-v2` — ND4, one landing ([#5](https://github.com/sourceplane/nextra-docs/pull/5), ND-5; the first tag of that shape), and ND5, the cirrus standard (no kiox, generated component docs, this context pack, and the workers.dev subdomain read from the Cloudflare connection instead of asked) |
| Before it | `baseline-v1` (ND3: three phases, `01-scaffold`, `02-site`, `03-docs`) |
| Proven live | `baseline-v1`: yes — a console bootstrap went live on stage and prod on 2026-10-15 (`nextra-live`, `bst_PW76WBTK`, 8m15s). `baseline-v2`'s one-landing shape: no — proven offline in Baseline CI only (risk ND-I) |

## Where to read

| Question | Page |
|---|---|
| What shipped, and every departure from upstream | `specs/epics/nextra-docs/IMPLEMENTATION-STATUS.md` |
| Why it is built this way | [decisions.md](decisions.md), then `specs/epics/nextra-docs/design.md` |
| What could still go wrong | [open-risks.md](open-risks.md), then `specs/epics/nextra-docs/risks-and-open-questions.md` |
| How to instantiate it | `BOOTSTRAP.md`, `docs/phases/` |
| What each component is | `apps/web/docs/`, `tests/web/docs/` (generated; `python3 tooling/catalog/gen-component-docs.py`) |

## Next

1. Bootstrap one site from `baseline-v2` from the console, and record its
   timings against the 6-minute estimate and baseline-v1's 8m15s (closes
   ND-I and ND4's last exit criterion).
