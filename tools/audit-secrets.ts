#!/usr/bin/env tsx
// Budget Beacon — audit:secrets
//
// Greps tracked files for known-bad patterns: hardcoded keystore passwords,
// alias names, third-party API keys. Exits non-zero on any hit so CI fails
// the build before the secret reaches a release artifact.
//
// Run via `npm run audit:secrets`.

import { execSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

type Pattern = {
  id: string;
  description: string;
  // String literal (case-insensitive) OR regex. Strings are used verbatim so a
  // pattern like `beacon_secure_123` matches the literal token in build.gradle.
  match: RegExp;
  // Files matching this allowlist regex are exempt (e.g. this audit script
  // itself, or docs that intentionally name a retired credential).
  allow?: RegExp;
};

const PATTERNS: Pattern[] = [
  {
    id: "keystore-password-literal",
    description: "Hardcoded Android keystore password literal",
    match: /beacon_secure_123/i,
    allow: /^(tools\/audit-secrets\.ts|docs\/APK_RELEASE\.md|CHANGELOG\.md|RELEASE_NOTES\.md|WHERE_LEFT_OFF\.md)$/,
  },
  {
    id: "gradle-storepassword-inline",
    description: 'storePassword "..." inline in *.gradle (use env vars or keystore.properties)',
    match: /storePassword\s+"[^"$][^"]*"/,
    allow: /^(tools\/audit-secrets\.ts)$/,
  },
  {
    id: "gradle-keypassword-inline",
    description: 'keyPassword "..." inline in *.gradle',
    match: /keyPassword\s+"[^"$][^"]*"/,
    allow: /^(tools\/audit-secrets\.ts)$/,
  },
  {
    id: "openai-key",
    description: "OpenAI-style API key",
    match: /sk-[A-Za-z0-9]{20,}/,
    allow: /^(tools\/audit-secrets\.ts)$/,
  },
  {
    id: "aws-access-key",
    description: "AWS access key ID",
    match: /AKIA[0-9A-Z]{16}/,
    allow: /^(tools\/audit-secrets\.ts)$/,
  },
  {
    id: "google-api-key",
    description: "Google API key",
    match: /AIza[0-9A-Za-z\-_]{35}/,
    allow: /^(tools\/audit-secrets\.ts)$/,
  },
  {
    id: "private-key-block",
    description: "PEM-encoded private key block",
    match: /-----BEGIN (?:RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----/,
    allow: /^(tools\/audit-secrets\.ts)$/,
  },
];

const FORBIDDEN_FILE_EXTENSIONS = [".keystore", ".jks", ".p12", ".pfx"];

function listTrackedFiles(): string[] {
  const out = execSync("git ls-files", { encoding: "utf8" });
  return out.split("\n").filter(Boolean);
}

function isBinary(buf: Buffer): boolean {
  for (let i = 0; i < Math.min(buf.length, 4096); i++) {
    if (buf[i] === 0) return true;
  }
  return false;
}

function main(): void {
  const repoRoot = execSync("git rev-parse --show-toplevel", { encoding: "utf8" }).trim();
  const tracked = listTrackedFiles();

  const hits: { file: string; pattern: string; line: number; snippet: string }[] = [];
  const forbiddenFiles: string[] = [];

  for (const rel of tracked) {
    for (const ext of FORBIDDEN_FILE_EXTENSIONS) {
      if (rel.toLowerCase().endsWith(ext)) {
        forbiddenFiles.push(rel);
      }
    }

    const abs = join(repoRoot, rel);
    if (!existsSync(abs)) continue;

    let buf: Buffer;
    try {
      buf = readFileSync(abs);
    } catch {
      continue;
    }
    if (isBinary(buf)) continue;
    const text = buf.toString("utf8");
    const lines = text.split("\n");

    for (const pattern of PATTERNS) {
      if (pattern.allow?.test(rel)) continue;
      for (let i = 0; i < lines.length; i++) {
        if (pattern.match.test(lines[i])) {
          hits.push({
            file: rel,
            pattern: pattern.id,
            line: i + 1,
            snippet: lines[i].trim().slice(0, 200),
          });
        }
      }
    }
  }

  if (hits.length === 0 && forbiddenFiles.length === 0) {
    console.log("audit:secrets — no hits across", tracked.length, "tracked files.");
    process.exit(0);
  }

  if (forbiddenFiles.length > 0) {
    console.error("\naudit:secrets — forbidden binary credentials tracked in git:");
    for (const f of forbiddenFiles) console.error(`  ${f}`);
    console.error(
      "\nUntrack with `git rm --cached <file>` and rotate the credential — it must be considered compromised once it has been in git history.",
    );
  }

  if (hits.length > 0) {
    console.error("\naudit:secrets — hits:");
    for (const h of hits) {
      console.error(`  ${h.file}:${h.line}  [${h.pattern}]  ${h.snippet}`);
    }
  }

  process.exit(1);
}

main();
