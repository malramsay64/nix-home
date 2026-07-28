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

function parseFindCommand(args: string[]): FindCommand {
  const result: FindCommand = {
    startPath: ".",
    patterns: [],
    excludePatterns: [],
  };

  let i = 0;
  while (i < args.length) {
    const arg = args[i];

    if (arg === "-name" && i + 1 < args.length) {
      result.patterns.push(args[i + 1]);
      i += 2;
    } else if (arg === "-type" && i + 1 < args.length) {
      result.type = args[i + 1] as "f" | "d" | "l";
      i += 2;
    } else if (arg === "-maxdepth" && i + 1 < args.length) {
      result.maxDepth = parseInt(args[i + 1], 10);
      i += 2;
    } else if (arg === "-not" || arg === "!") {
      if (i + 1 < args.length && args[i + 1] === "-name" && i + 2 < args.length) {
        result.excludePatterns.push(args[i + 2]);
        i += 3;
      } else {
        i += 1;
      }
    } else if (!arg.startsWith("-")) {
      // First non-flag argument is the start path
      if (!result.startPath || result.startPath === ".") {
        result.startPath = arg;
      }
      i += 1;
    } else {
      i += 1;
    }
  }

  return result;
}

function translateToFd(cmd: FindCommand, intent: SearchIntent): string {
  const scope = calculateScope(cmd.startPath, intent);

  // fd syntax: fd [options] [pattern] [path]
  let fdArgs: string[] = [];

  // Add type filter if specified
  if (cmd.type) {
    if (cmd.type === "f") fdArgs.push("--type", "f");
    else if (cmd.type === "d") fdArgs.push("--type", "d");
  }

  // Add max depth if specified
  if (cmd.maxDepth) {
    fdArgs.push("--max-depth", cmd.maxDepth.toString());
  }

  // Add exclude patterns
  for (const excl of cmd.excludePatterns) {
    fdArgs.push("--exclude", excl);
  }

  // Add the search pattern (fd expects it as argument, not -name flag)
  const pattern = cmd.patterns.length > 0 ? cmd.patterns[0] : "*";

  // Construct the full command
  // fd returns absolute paths by default, similar to find
  return `fd ${fdArgs.join(" ")} ${pattern} ${scope}`.trim();
}

function translateToRg(
  cmd: FindCommand,
  intent: SearchIntent,
  searchContent?: string
): string {
  const scope = calculateScope(cmd.startPath, intent);

  // rg syntax: rg [options] [pattern] [path]
  let rgArgs: string[] = [];

  // Respect type filter
  if (cmd.type === "f") {
    rgArgs.push("--files");
  }

  // Exclude patterns
  for (const excl of cmd.excludePatterns) {
    rgArgs.push("--glob", `!${excl}`);
  }

  // Default to file listing when used as find replacement
  rgArgs.push("--files");

  // Max depth if specified
  if (cmd.maxDepth) {
    rgArgs.push("--max-depth", cmd.maxDepth.toString());
  }

  // Construct command
  // If searchContent is provided, use it; otherwise use pattern from find
  const query = searchContent || (cmd.patterns.length > 0 ? cmd.patterns[0] : "");
  return `rg ${rgArgs.join(" ")} ${query} ${scope}`.trim();
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "find") return undefined;

    try {
      // Parse the find command arguments
      const findCmd = parseFindCommand(
        (event.input.args || []) as string[]
      );

      // Detect search intent
      const intent = detectIntent(
        findCmd.patterns,
        findCmd.patterns[0]
      );

      // Determine which tool to use
      let command: string;

      if (intent === "code" || intent === "config") {
        // Use fd for file discovery
        command = translateToFd(findCmd, intent);
        if (ctx.hasUI) {
          ctx.ui.notify(
            `find → fd: Routing file search to fd with scope detection`,
            "info"
          );
        }
      } else {
        // Use fd for general file searches
        command = translateToFd(findCmd, intent);
        if (ctx.hasUI) {
          ctx.ui.notify(
            `find → fd: Routing to fd for safer file discovery`,
            "info"
          );
        }
      }

      // Execute the translated command
      try {
        const result = execSync(command, {
          encoding: "utf-8",
          stdio: ["pipe", "pipe", "pipe"],
        });

        return {
          output: result,
        };
      } catch (execError: any) {
        // fd/rg exited with error (e.g., no results found)
        if (execError.status === 1) {
          return {
            output: "", // No results, return empty
          };
        }
        throw execError;
      }
    } catch (error) {
      // Safety or parsing errors
      const message =
        error instanceof Error ? error.message : String(error);
      return {
        error: message,
      };
    }
  });
}
