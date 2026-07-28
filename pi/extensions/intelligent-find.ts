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

export default function (pi: ExtensionAPI) {
  // TODO: Implement tool registration and parsing
}
