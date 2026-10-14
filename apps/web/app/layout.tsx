import type { Metadata } from 'next'
import type { ReactNode } from 'react'
import { Footer, Layout, Navbar } from 'nextra-theme-docs'
import { Head } from 'nextra/components'
import { getPageMap } from 'nextra/page-map'
import 'nextra-theme-docs/style.css'

// Upstream theme.config.tsx, expressed through nextra-theme-docs 4's
// Layout / Navbar / Footer: the logo, the project and chat links, the docs
// repository base and the footer text. The title template is what Nextra 2's
// docs theme used by default.
export const metadata: Metadata = {
  title: {
    default: 'My Project',
    template: '%s – Nextra',
  },
  description: 'Nextra docs template',
}

const navbar = (
  <Navbar
    logo={<span>My Project</span>}
    projectLink="https://github.com/shuding/nextra-docs-template"
    chatLink="https://discord.com"
  />
)

const footer = <Footer>Nextra Docs Template</Footer>

export default async function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="en" dir="ltr" suppressHydrationWarning>
      <Head />
      <body>
        <Layout
          navbar={navbar}
          pageMap={await getPageMap()}
          docsRepositoryBase="https://github.com/shuding/nextra-docs-template"
          footer={footer}
        >
          {children}
        </Layout>
      </body>
    </html>
  )
}
