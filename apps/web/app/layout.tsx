import type { Metadata } from 'next'
import type { ReactNode } from 'react'
import { Footer, Layout, Navbar } from 'nextra-theme-docs'
import { Head } from 'nextra/components'
import { getPageMap } from 'nextra/page-map'
import 'nextra-theme-docs/style.css'
import { DOCS_REPOSITORY_BASE, SITE_NAME, SOURCE_URL } from './site'

// Upstream theme.config.tsx, expressed through nextra-theme-docs 4's
// Layout / Navbar / Footer: the logo, the project and chat links, the docs
// repository base and the footer text. The title template has the shape
// Nextra 2's docs theme used by default (`%s – <name>`). The name and the
// repository are the site's own, from ./site.
export const metadata: Metadata = {
  title: {
    default: SITE_NAME,
    template: `%s – ${SITE_NAME}`,
  },
  description: 'Nextra docs template',
}

const navbar = (
  <Navbar
    logo={<span>{SITE_NAME}</span>}
    projectLink={SOURCE_URL}
    chatLink="https://discord.com"
  />
)

const footer = <Footer>{SITE_NAME}</Footer>

export default async function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="en" dir="ltr" suppressHydrationWarning>
      <Head />
      <body>
        <Layout
          navbar={navbar}
          pageMap={await getPageMap()}
          docsRepositoryBase={DOCS_REPOSITORY_BASE}
          footer={footer}
        >
          {children}
        </Layout>
      </body>
    </html>
  )
}
