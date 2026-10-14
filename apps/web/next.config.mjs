import path from "node:path";
import { fileURLToPath } from "node:url";
import nextra from "nextra";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Nextra 4: MDX pages come from content/ through app/[[...mdxPath]]/page.tsx;
// search is Pagefind, indexed by the `build` script after `next build`.
const withNextra = nextra({});

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Required by @opennextjs/cloudflare, which bundles `.next/standalone/**`
  // into the Worker. Trace from the monorepo root so workspace dependencies
  // resolve from the root node_modules.
  output: "standalone",
  outputFileTracingRoot: path.join(__dirname, "../.."),
  typescript: { ignoreBuildErrors: false },
};

export default withNextra(nextConfig);
