/**
 * Intelligent Find Replacement
 *
 * Intercepts find tool calls and routes to rg (ripgrep) or fd (file-discovery)
 * based on search intent, with automatic directory scoping for safety and performance.
 *
 * Safety constraints:
 * - Never searches from filesystem root (/)
 * - Never searches system directories (/usr, /opt, /nix/store, etc.)
 * - Scopes to CWD + identified project root or home directory
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "child_process";
import { homedir } from "os";
import { resolve } from "path";

// File extension patterns for intent detection
const CODE_EXTENSIONS = [
  ".ts",
  ".tsx",
  ".rs",
  ".js",
  ".jsx",
  ".py",
  ".go",
  ".nix",
  ".java",
  ".cpp",
  ".c",
  ".h",
  ".swift",
  ".kt",
  ".scala",
  ".clj",
  ".rb",
  ".sh",
  ".bash",
];

const CONFIG_EXTENSIONS = [
  ".json",
  ".yaml",
  ".yml",
  ".toml",
  ".ini",
  ".conf",
  ".config",
];

const CONFIG_FILENAMES = [".env", ".gitignore", ".npmrc", ".editorconfig"];

// Project markers to identify root when walking up directory tree
const PROJECT_MARKERS = [
  ".git",
  ".jj",
  "flake.nix",
  "package.json",
  "Cargo.toml",
  "pyproject.toml",
  "go.mod",
  "mix.exs",
  "pubspec.yaml",
];

// System directories that should never be searched
const BLOCKED_PATHS = ["/usr", "/opt", "/nix/store", "/etc", "/sys", "/proc"];

interface FindCommand {
  startPath: string;
  patterns: string[];
  excludePatterns: string[];
  type?: "f" | "d" | "l";
  maxDepth?: number;
  nameOnly?: boolean;
}

type SearchIntent = "code" | "config" | "general";

function detectIntent(patterns: string[], fileName?: string): SearchIntent {
  // Check filename first (highest priority)
  if (fileName) {
    const lower = fileName.toLowerCase();
    if (CONFIG_FILENAMES.includes(lower)) return "config";
    for (const ext of CONFIG_EXTENSIONS) {
      if (lower.endsWith(ext)) return "config";
    }
    for (const ext of CODE_EXTENSIONS) {
      if (lower.endsWith(ext)) return "code";
    }
  }

  // Check patterns for file extensions
  for (const pattern of patterns) {
    const lower = pattern.toLowerCase();

    // Check for explicit file type patterns (e.g., "*.ts", "*.json")
    if (lower.includes("*.") || lower.includes(".")) {
      const ext = lower.match(/\.[\w]+/)?.[0];
      if (ext) {
        if (CODE_EXTENSIONS.includes(ext)) return "code";
        if (CONFIG_EXTENSIONS.includes(ext)) return "config";
      }
    }

    // Check for grep/content search indicators
    if (
      pattern.includes("-exec") ||
      pattern.includes("grep") ||
      pattern.includes("xargs")
    ) {
      // Content search - more likely code
      return "code";
    }

    // Check if pattern mentions config-related keywords
    if (/config|env|rc$|json|yaml|toml/i.test(pattern)) {
      return "config";
    }
  }

  // Default to general for unknown patterns
  return "general";
}

// Test cases (for manual verification):
// detectIntent([".ts", "*.tsx"]) -> "code"
// detectIntent([".json"]) -> "config"
// detectIntent([".env"]) -> "config"
// detectIntent(["*.txt"]) -> "general"

function isSystemPath(path: string): boolean {
  const normalized = resolve(path);
  return BLOCKED_PATHS.some(
    (blocked) =>
      normalized === blocked || normalized.startsWith(blocked + "/")
  );
}

function findProjectRoot(startPath: string): string | null {
  let current = resolve(startPath);
  const root = "/";

  // Walk up max 10 levels to find project marker
  for (let i = 0; i < 10; i++) {
    if (current === root) break;

    for (const marker of PROJECT_MARKERS) {
      try {
        execSync(`test -e "${current}/${marker}"`, { stdio: "ignore" });
        return current;
      } catch {
        // Marker doesn't exist, continue
      }
    }

    // Move up one directory
    const parent = current.split("/").slice(0, -1).join("/") || "/";
    if (parent === current) break; // Reached root
    current = parent;
  }

  return null;
}

function calculateScope(startPath: string, intent: SearchIntent): string {
  const normalized = resolve(startPath);
  const home = homedir();

  // Safety check: reject system paths and root
  if (isSystemPath(normalized) || normalized === "/") {
    throw new Error(
      `find: cannot search in system path "${normalized}" for safety/performance reasons. ` +
        `Use rg/fd in a scoped directory within your project or home directory.`
    );
  }

  // If starting path is not in home, reject it
  if (!normalized.startsWith(home)) {
    throw new Error(
      `find: cannot search outside home directory (${home}). ` +
        `Requested path: ${normalized}`
    );
  }

  // For code searches: try to find project root, otherwise use home
  if (intent === "code") {
    const projectRoot = findProjectRoot(normalized);
    if (projectRoot) return projectRoot;
  }

  // For config searches: allow home + project config dirs
  if (intent === "config") {
    const projectRoot = findProjectRoot(normalized);
    // Config searches can span home + project, but we'll search project root if found
    if (projectRoot) return projectRoot;
    return home;
  }

  // For general: stick to CWD only
  return normalized;
}

// Scope detection test cases:
// calculateScope("/home/user/projects/myapp", "code") -> "/home/user/projects/myapp" (project root)
// calculateScope("/home/user/projects/myapp/src", "code") -> "/home/user/projects/myapp" (walk up to project)
// calculateScope("/home/user", "config") -> "/home/user"
// calculateScope("/usr/bin", "code") -> throws error (system path)
// calculateScope("/", "code") -> throws error (root)

export default function (pi: ExtensionAPI) {
  // TODO: Implement tool registration and parsing
}
