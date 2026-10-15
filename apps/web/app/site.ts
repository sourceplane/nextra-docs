// The site's identity, written once. The navbar logo, the page titles (the
// default and the `%s – <name>` template) and the footer read SITE_NAME; the
// navbar's GitHub link and every page's "Edit this page" link are built on
// SOURCE_URL. A product built from this baseline gets both rewritten to its
// own name and repository at instantiation, so keep them literal and on one
// line each.
export const SITE_NAME = "My Project"
export const SOURCE_URL = "https://github.com/sourceplane/nextra-docs"

// Where the pages live in that repository: `content/` sits in `apps/web`, and
// Nextra appends each page's path under it to this base for "Edit this page".
export const DOCS_REPOSITORY_BASE = `${SOURCE_URL}/tree/main/apps/web`
