// Checks the links between the markdown files of this repo: every relative link points to a file
// or folder that exists, and every #anchor to a heading of its page. Links to the web are not
// fetched. Run: node tools/check-links.mjs
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import path from "node:path";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const SKIP = new Set(["node_modules", ".git", ".sf", ".sfdx"]);

function markdownFiles(dir) {
  return readdirSync(dir).flatMap((name) => {
    if (SKIP.has(name)) return [];
    const full = path.join(dir, name);
    if (statSync(full).isDirectory()) return markdownFiles(full);
    return name.endsWith(".md") ? [full] : [];
  });
}

/** without fenced code blocks and inline code, where a [x](y) is not a link */
function withoutCode(text) {
  return text.replace(/^(```|~~~)[\s\S]*?^\1/gm, "").replace(/`[^`\n]*`/g, "");
}

/** GitHub's anchor of a heading: lower case, no punctuation, spaces to dashes; repeats get -1, -2 */
export function anchors(text) {
  const seen = new Map();
  const result = new Set();
  for (const [, heading] of withoutCode(text).matchAll(/^#{1,6}\s+(.+?)\s*#*\s*$/gm)) {
    const base = heading
      .replace(/<[^>]+>/g, "")
      .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
      .toLowerCase()
      .replace(/[^\p{L}\p{N}\s_-]/gu, "")
      .replace(/\s/g, "-");
    const count = seen.get(base) ?? 0;
    seen.set(base, count + 1);
    result.add(count === 0 ? base : `${base}-${count}`);
  }
  return result;
}

export function check(root = ROOT) {
  const problems = [];
  const cache = new Map();
  const anchorsOf = (file) => {
    if (!cache.has(file)) cache.set(file, anchors(readFileSync(file, "utf8")));
    return cache.get(file);
  };
  for (const file of markdownFiles(root)) {
    const text = withoutCode(readFileSync(file, "utf8"));
    for (const [, target] of text.matchAll(/!?\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/g)) {
      if (/^[a-z][a-z0-9+.-]*:/i.test(target)) continue; // https:, mailto:, ...
      const [linkPath, anchor] = target.split("#");
      const to = linkPath ? path.resolve(path.dirname(file), decodeURI(linkPath)) : file;
      const where = path.relative(root, file);
      if (!existsSync(to)) {
        problems.push(`${where}: ${target}: no such file`);
      } else if (anchor && to.endsWith(".md") && !anchorsOf(to).has(decodeURI(anchor).toLowerCase())) {
        problems.push(`${where}: ${target}: no such heading`);
      }
    }
  }
  return problems;
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
  const problems = check();
  for (const problem of problems) console.error(problem);
  console.log(problems.length === 0 ? "All links point somewhere." : `${problems.length} broken link(s).`);
  process.exit(problems.length === 0 ? 0 : 1);
}
