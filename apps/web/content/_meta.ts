import type { MetaRecord } from 'nextra'

// Upstream pages/_meta.json, as Nextra 4's _meta module: the sidebar order,
// and the two `type: 'page'` entries that sit in the navbar instead.
const meta: MetaRecord = {
  index: 'Introduction',
  another: 'Another Page',
  advanced: 'Advanced (A Folder)',
  about: {
    title: 'About',
    type: 'page',
  },
  contact: {
    title: 'Contact ↗',
    type: 'page',
    href: 'https://twitter.com/shuding_',
  },
}

export default meta
