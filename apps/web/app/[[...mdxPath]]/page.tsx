import { generateStaticParamsFor, importPage } from 'nextra/pages'
import { useMDXComponents as getMDXComponents } from '../../mdx-components'

// Every page under content/ is pre-rendered at build time. A Worker has no
// filesystem at request time, so anything outside the page map is a 404.
export const generateStaticParams = generateStaticParamsFor('mdxPath')
export const dynamicParams = false

type PageProps = Readonly<{ params: Promise<{ mdxPath?: string[] }> }>

export async function generateMetadata(props: PageProps) {
  const params = await props.params
  const { metadata } = await importPage(params.mdxPath)
  return metadata
}

const Wrapper = getMDXComponents().wrapper!

export default async function Page(props: PageProps) {
  const params = await props.params
  const { default: MDXContent, toc, metadata, sourceCode } = await importPage(params.mdxPath)
  return (
    <Wrapper toc={toc} metadata={metadata} sourceCode={sourceCode}>
      <MDXContent {...props} params={params} />
    </Wrapper>
  )
}
