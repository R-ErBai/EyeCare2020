import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const root = join(import.meta.dirname, "..");
const files = [
  "EyeCare2020.xcodeproj/project.pbxproj",
  "EyeCare2020.xcodeproj/xcshareddata/xcschemes/EyeCare2020.xcscheme",
];
const sources = files.map((file) => readFileSync(join(root, file), "utf8"));
const nonHexId = /\b(?=[A-Z0-9]*[G-Z])[A-Z][A-Z0-9]{23}\b/g;
const identifiers = new Set(sources.flatMap((source) => source.match(nonHexId) ?? []));
const replacements = new Map(
  [...identifiers].map((identifier) => [
    identifier,
    createHash("sha256").update(identifier).digest("hex").slice(0, 24).toUpperCase(),
  ]),
);

for (let index = 0; index < files.length; index += 1) {
  let source = sources[index];
  for (const [before, after] of replacements) {
    source = source.replaceAll(before, after);
  }
  writeFileSync(join(root, files[index]), source);
}

console.log(`Normalized ${replacements.size} project identifiers`);
