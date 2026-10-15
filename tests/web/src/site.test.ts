import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";

const appDir = path.resolve(__dirname, "../../../apps/web");

describe("site identity (apps/web/app/site.ts)", () => {
  it("names the site and links its source repository", async () => {
    const { SITE_NAME, SOURCE_URL } = await import("@/app/site");
    expect(SITE_NAME.trim()).not.toBe("");
    expect(SOURCE_URL).toMatch(/^https:\/\/github\.com\/[A-Za-z0-9-]+\/[a-z0-9-]+$/);
  });

  it("points 'Edit this page' at the content in that repository", async () => {
    const { DOCS_REPOSITORY_BASE, SOURCE_URL } = await import("@/app/site");
    expect(DOCS_REPOSITORY_BASE).toBe(`${SOURCE_URL}/tree/main/apps/web`);
    expect(fs.existsSync(path.join(appDir, "content"))).toBe(true);
  });

  it("is the one place the theme takes its name and links from", () => {
    // The logo, the titles, the footer, the GitHub link and the docs base all
    // read ./site; none of them may be spelled in the layout again.
    const layout = fs.readFileSync(path.join(appDir, "app/layout.tsx"), "utf8");
    expect(layout).toMatch(/from '\.\/site'/);
    expect(layout).toContain("logo={<span>{SITE_NAME}</span>}");
    expect(layout).toContain("projectLink={SOURCE_URL}");
    expect(layout).toContain("docsRepositoryBase={DOCS_REPOSITORY_BASE}");
    expect(layout).toContain("template: `%s – ${SITE_NAME}`");
    expect(layout).not.toMatch(/https:\/\/github\.com\//);
  });
});
