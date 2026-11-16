// Checks the markdown files of this repo: every relative link points to a file or folder that
// exists, every #anchor to a heading of its page, and a full GitHub link into this repo's
// examples/ to a path that exists here. Other links to the web are not fetched. It also finds a
// binding written in quotes (value="{x}"), which LWC does not take. Run: node tools/check-links.mjs
import {
  existsSync,
  readFileSync,
  readdirSync,
  realpathSync,
  statSync
} from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SKIP = new Set(["node_modules", ".git", ".sf", ".sfdx"]);
// a link into this repo on GitHub: checked as the local path after it
const THIS_REPO =
  /^https:\/\/github\.com\/itprolet\/wizard-force-examples\/(?:tree|blob)\/main\/([^?#]*)/;
// a binding in quotes: value="{x}" or value='{x}'; not initial-model="{}" (JSON)
const QUOTED_BINDING = /=\s*(["'])\{[\w.]+\}\1/;

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
  for (const [, heading] of withoutCode(text).matchAll(
    /^#{1,6}\s+(.+?)\s*#*\s*$/gm
  )) {
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
  // absolute, as the targets are (path.resolve): a relative root would put every link outside docs
  root = path.resolve(root);
  const problems = [];
  const cache = new Map();
  const anchorsOf = (file) => {
    if (!cache.has(file)) cache.set(file, anchors(readFileSync(file, "utf8")));
    return cache.get(file);
  };
  const docs = path.join(root, "docs");
  for (const file of markdownFiles(root)) {
    const source = readFileSync(file, "utf8");
    const where = path.relative(root, file);
    // every line, code blocks included (where a template is shown); not inline code in the text,
    // where a troubleshooting entry shows the mistake itself
    source.split("\n").forEach((line, index) => {
      if (QUOTED_BINDING.test(line.replace(/`[^`\n]*`/g, ""))) {
        problems.push(
          `${where}:${index + 1}: a binding in quotes (write value={x}, not value="{x}")`
        );
      }
    });
    const text = withoutCode(source);
    for (const [, target] of text.matchAll(
      /!?\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/g
    )) {
      const ours = THIS_REPO.exec(target);
      if (ours) {
        // a link into this repo's examples (or any path of it) on GitHub: the path must exist here
        if (!existsSync(path.join(root, decodeURI(ours[1])))) {
          problems.push(`${where}: ${target}: no such path in this repo`);
        }
        continue;
      }
      if (/^[a-z][a-z0-9+.-]*:/i.test(target)) continue; // https:, mailto:, ...
      const [linkPath, anchor] = target.split("#");
      const to = linkPath
        ? path.resolve(path.dirname(file), decodeURI(linkPath))
        : file;
      const inDocs = (name) =>
        name === docs || name.startsWith(docs + path.sep);
      if (inDocs(file) && !inDocs(to)) {
        problems.push(
          `${where}: ${target}: leaves docs/, which the site does not have; use a full GitHub link`
        );
      } else if (!existsSync(to)) {
        problems.push(`${where}: ${target}: no such file`);
      } else if (
        anchor &&
        to.endsWith(".md") &&
        !anchorsOf(to).has(decodeURI(anchor).toLowerCase())
      ) {
        problems.push(`${where}: ${target}: no such heading`);
      }
    }
  }
  return problems;
}

/** run as a script, also through a symbolic link (argv keeps the link, import.meta.url is real) */
function runAsScript() {
  if (!process.argv[1]) return false;
  try {
    return realpathSync(process.argv[1]) === fileURLToPath(import.meta.url);
  } catch {
    return false;
  }
}

if (runAsScript()) {
  const problems = check();
  for (const problem of problems) console.error(problem);
  console.log(
    problems.length === 0
      ? "All links point somewhere."
      : `${problems.length} problem(s).`
  );
  process.exit(problems.length === 0 ? 0 : 1);
}
