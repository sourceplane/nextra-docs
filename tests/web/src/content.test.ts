import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";

// Nextra 4 reads the page map from `content/` and orders it by `_meta`. These
// tests pin the port to the upstream template's five pages and its sidebar /
// navbar layout (pages/_meta.json upstream, content/_meta.ts here).
const contentDir = path.resolve(__dirname, "../../../apps/web/content");

function listMdx(dir: string, prefix = ""): string[] {
  return fs
    .readdirSync(dir, { withFileTypes: true })
    .flatMap((entry) => {
      if (entry.isDirectory()) return listMdx(path.join(dir, entry.name), `${prefix}${entry.name}/`);
      return entry.name.endsWith(".mdx") ? [`${prefix}${entry.name.replace(/\.mdx$/, "")}`] : [];
    })
    .sort();
}

describe("content directory (apps/web/content)", () => {
  it("holds exactly the upstream template's five pages", () => {
    expect(listMdx(contentDir)).toEqual(["about", "advanced", "advanced/satori", "another", "index"]);
  });

  it("keeps the upstream page text", () => {
    const index = fs.readFileSync(path.join(contentDir, "index.mdx"), "utf8");
    expect(index).toContain("# Introduction");
    expect(index).toContain("Welcome to Nextra! This is a basic docs template.");
    const satori = fs.readFileSync(path.join(contentDir, "advanced/satori.mdx"), "utf8");
    expect(satori).toContain("Satori (悟り) is a Japanese Buddhist term for awakening");
  });
});

describe("_meta (apps/web/content/_meta.ts)", () => {
  it("orders the sidebar as upstream pages/_meta.json did", async () => {
    const { default: meta } = await import("@/content/_meta");
    expect(Object.keys(meta)).toEqual(["index", "another", "advanced", "about", "contact"]);
    expect(meta.index).toBe("Introduction");
    expect(meta.another).toBe("Another Page");
    expect(meta.advanced).toBe("Advanced (A Folder)");
  });

  it("puts About and the external Contact link in the navbar", async () => {
    const { default: meta } = await import("@/content/_meta");
    const navbar = Object.entries(meta).filter(
      ([, item]) => typeof item === "object" && item !== null && "type" in item && item.type === "page",
    );
    expect(navbar.map(([key]) => key)).toEqual(["about", "contact"]);
    expect(meta.contact).toMatchObject({ title: "Contact ↗", href: "https://twitter.com/shuding_" });
  });

  it("names only pages that exist in content/", async () => {
    const { default: meta } = await import("@/content/_meta");
    const pages = listMdx(contentDir);
    for (const [key, item] of Object.entries(meta)) {
      const external = typeof item === "object" && item !== null && "href" in item;
      if (!external) expect(pages).toContain(key);
    }
  });
});
