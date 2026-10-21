# nextra-docs — open risks

What is not yet proven or not yet decided. The full write-up of every risk,
including the accepted and resolved ones, is
`specs/epics/nextra-docs/risks-and-open-questions.md`; this page lists only
what is still live, so it should be short.

| ID | Risk | State | What closes it |
|---|---|---|---|
| ND-I | The one-landing shape (ND4, first tagged `baseline-v2`) is not yet proven live; `baseline-v1`'s three phases were (2026-10-15, 8m15s) | OPEN | One console bootstrap from `baseline-v2` |
| ND-B | OpenNext and Next.js version drift: Next is pinned at 16.3.8 because 16.4.x fails at worker boot on `@opennextjs/cloudflare` 1.20.11 | Mitigated (watch) | An adapter release that admits the next Next, taken in a deliberate PR that re-runs the build and the preview |

Accepted, and worth knowing before you change them: ND-G (no "Last updated"
dates in a staged build), ND-H (Worker size), ND-J (a custom domain is the
owner's step).
