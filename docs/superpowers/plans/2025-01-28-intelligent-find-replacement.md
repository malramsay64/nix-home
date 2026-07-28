# Intelligent Find Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Pi's built-in `find` tool with a smart extension that routes searches to `rg` or `fd` with automatic scope detection, improving performance and preventing unsafe root-level searches.

**Architecture:** A Pi extension that intercepts `find` tool invocations, analyzes the search intent (code/config/general), calculates safe directory boundaries, and translates the find command to either `fd` (file-discovery) or `rg` (content search). The extension enforces safety constraints (no root searches, no system directories) before execution.

**Tech Stack:** 
- TypeScript (Pi extension language)
- Pi ExtensionAPI for tool interception
- `rg` (ripgrep) and `fd` for fast file operations
- Bash for subprocesses

## Global Constraints

- Must not allow searches from filesystem root (`/`) or system directories (`/usr`, `/opt`, `/nix/store`)
- Must use only ripgrep and fd as managed by pi.nix extraPackages
- Must preserve backward compatibility with find command syntax as much as possible
- Must log tool selection for transparency ("Routing to fd with scope...")
- Must default to CWD if scope cannot be determined (safe-first approach)

---

## File Structure

**Files to create:**
- `pi/extensions/intelligent-find.ts` — Main extension implementing tool override, intent detection, scope calculation, and command translation

**Files to modify:**
- `pi.nix` — Add `fd` to `extraPackages` (if not present), add `intelligent-find.ts` to `settings.extensions`

**No test files needed** — Testing will be manual integration tests in your environment

---

## Task 1: Verify and Update Dependencies in pi.nix

**Files:**
- Modify: `pi.nix` (extraPackages section)
- Modify: `pi.nix` (settings.extensions section)

**Interfaces:**
- Consumes: Existing pi.nix structure
- Produces: Updated pi.nix with fd in extraPackages and intelligent-find in extensions list

- [ ] **Step 1: Check if fd is already in extraPackages**

Run: `grep -n "fd" pi.nix`

Expected: Either shows `fd` package in extraPackages or no match

- [ ] **Step 2: If fd is not present, add it to extraPackages**

In `pi.nix`, find the `extraPackages = with pkgs; [` section (around line 15-30). Add `fd` to the list:

```nix
extraPackages = with pkgs; [
  nodejs
  bun
  kubectl
  kubernetes-helm
  terraform
  awscli2
  jq
  yq-go
  httpie
  uv
  duckdb
  ripgrep
  fd          # <-- ADD THIS LINE
  jujutsu
];
```

- [ ] **Step 3: Add intelligent-find extension to settings.extensions**

In `pi.nix`, find the `extensions = [` section (around line 50-55). Update it:

```nix
extensions = [
  "extensions/permission-gate.ts"
  "extensions/intelligent-find.ts"  # <-- ADD THIS LINE
];
```

- [ ] **Step 4: Rebuild home-manager to apply changes**

Run: `home-manager switch --flake .`

Expected: No errors, fd and new extension configuration applied

- [ ] **Step 5: Verify fd is available on PATH**

Run: `which fd`

Expected: Output like `/nix/store/.../bin/fd`

- [ ] **Step 6: Commit**

```bash
jj add pi.nix
jj commit -m "feat: add fd package and intelligent-find extension to pi.nix"
```

---

## Task 2: Create Extension Scaffolding and Type Definitions

**Files:**
- Create: `pi/extensions/intelligent-find.ts`

**Interfaces:**
- Consumes: Pi ExtensionAPI (pi.on, ctx.ui, ctx.runBash)
- Produces: Exported extension function with tool override registration

- [ ] **Step 1: Create the extension file with TypeScript header and imports**

Create `pi/extensions/intelligent-find.ts` with:

```typescript
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

export default function (pi: ExtensionAPI) {
  // TODO: Implement tool registration and parsing
}
```

- [ ] **Step 2: Verify file was created**

Run: `ls -l pi/extensions/intelligent-find.ts`

Expected: File exists with content

- [ ] **Step 3: Commit scaffolding**

```bash
jj add pi/extensions/intelligent-find.ts
jj commit -m "feat: scaffold intelligent-find extension with type definitions"
```

---

## Task 3: Implement Intent Detection (Code vs Config vs General)

**Files:**
- Modify: `pi/extensions/intelligent-find.ts`

**Interfaces:**
- Consumes: CODE_EXTENSIONS, CONFIG_EXTENSIONS, CONFIG_FILENAMES (defined in Task 2)
- Produces: `detectIntent(patterns: string[]): 'code' | 'config' | 'general'` function

- [ ] **Step 1: Add intent detection function**

Add this function to `pi/extensions/intelligent-find.ts` before the export default:

```typescript
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
      const ext = lower.match(/\.\w+/)?.[0];
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
    if (
      /config|\.env|rc$|json|yaml|toml/i.test(pattern)
    ) {
      return "config";
    }
  }

  // Default to general for unknown patterns
  return "general";
}
```

- [ ] **Step 2: Test the function with sample inputs**

In the same file, add a simple test comment showing expected behavior:

```typescript
// Test cases (for manual verification):
// detectIntent([".ts", "*.tsx"]) -> "code"
// detectIntent([".json"]) -> "config"
// detectIntent([".env"]) -> "config"
// detectIntent(["*.txt"]) -> "general"
```

- [ ] **Step 3: Commit intent detection**

```bash
jj add pi/extensions/intelligent-find.ts
jj commit -m "feat: implement intent detection for code/config/general searches"
```

---

## Task 4: Implement Scope Detection (Directory Boundaries)

**Files:**
- Modify: `pi/extensions/intelligent-find.ts`

**Interfaces:**
- Consumes: PROJECT_MARKERS, BLOCKED_PATHS, homedir(), detectIntent()
- Produces: `calculateScope(startPath: string, intent: SearchIntent): string` function that returns safe directory to search within

- [ ] **Step 1: Add scope detection helper functions**

Add these functions before `export default`:

```typescript
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
```

- [ ] **Step 2: Add validation test cases**

Add comment showing expected behavior:

```typescript
// Scope detection test cases:
// calculateScope("/home/user/projects/myapp", "code") -> "/home/user/projects/myapp" (project root)
// calculateScope("/home/user/projects/myapp/src", "code") -> "/home/user/projects/myapp" (walk up to project)
// calculateScope("/home/user", "config") -> "/home/user"
// calculateScope("/usr/bin", "code") -> throws error (system path)
// calculateScope("/", "code") -> throws error (root)
```

- [ ] **Step 3: Commit scope detection**

```bash
jj add pi/extensions/intelligent-find.ts
jj commit -m "feat: implement directory scope detection with safety constraints"
```

---

## Task 5: Implement Find Command Parser

**Files:**
- Modify: `pi/extensions/intelligent-find.ts`

**Interfaces:**
- Consumes: FindCommand interface (defined in Task 2)
- Produces: `parseFindCommand(args: string[]): FindCommand` function

- [ ] **Step 1: Add find command parser**

Add this function before `export default`:

```typescript
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
```

- [ ] **Step 2: Commit parser**

```bash
jj add pi/extensions/intelligent-find.ts
jj commit -m "feat: implement find command parser"
```

---

## Task 6: Implement Find→FD Translation

**Files:**
- Modify: `pi/extensions/intelligent-find.ts`

**Interfaces:**
- Consumes: FindCommand, calculateScope(), detectIntent()
- Produces: `translateToFd(cmd: FindCommand): string` function that returns fd command with arguments

- [ ] **Step 1: Add fd translation function**

Add before `export default`:

```typescript
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
    fdArgs.push("--max-one-result" + cmd.maxDepth);
  }

  // Add exclude patterns
  for (const excl of cmd.excludePatterns) {
    fdArgs.push("--exclude", excl);
  }

  // Add the search pattern (fd expects it as argument, not -name flag)
  const pattern = cmd.patterns.length > 0 ? cmd.patterns[0] : "*";

  // Construct the full command
  // fd returns absolute paths by default, similar to find
  return `fd ${fdArgs.join(" ")} ${pattern} ${scope}`;
}
```

- [ ] **Step 2: Commit fd translation**

```bash
jj add pi/extensions/intelligent-find.ts
jj commit -m "feat: implement find to fd translation"
```

---

## Task 7: Implement Find→RG Translation

**Files:**
- Modify: `pi/extensions/intelligent-find.ts`

**Interfaces:**
- Consumes: FindCommand, calculateScope(), detectIntent()
- Produces: `translateToRg(cmd: FindCommand): string` function that returns rg command

- [ ] **Step 1: Add rg translation function**

Add before `export default`:

```typescript
function translateToRg(
  cmd: FindCommand,
  intent: SearchIntent,
  searchContent: string
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
  return `rg ${rgArgs.join(" ")} ${query} ${scope}`;
}
```

- [ ] **Step 2: Commit rg translation**

```bash
jj add pi/extensions/intelligent-find.ts
jj commit -m "feat: implement find to rg translation"
```

---

## Task 8: Implement Tool Registration and Command Interception

**Files:**
- Modify: `pi/extensions/intelligent-find.ts`

**Interfaces:**
- Consumes: parseFindCommand(), detectIntent(), translateToFd(), translateToRg(), all helper functions
- Produces: Complete extension that registers as tool override and intercepts find calls

- [ ] **Step 1: Replace the empty export default with full implementation**

Update the `export default function (pi: ExtensionAPI) {` block to:

```typescript
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
```

- [ ] **Step 2: Verify TypeScript syntax**

Run: `tsc --noEmit pi/extensions/intelligent-find.ts 2>&1 | head -20`

Expected: Either no output (success) or clear type errors to fix

- [ ] **Step 3: Commit tool registration**

```bash
jj add pi/extensions/intelligent-find.ts
jj commit -m "feat: register intelligent-find as tool override and implement command interception"
```

---

## Task 9: Test the Extension in Your Environment

**Files:**
- Use: `pi/extensions/intelligent-find.ts` (no changes, just testing)

**Interfaces:**
- Consumes: Entire extension
- Produces: Verified working extension ready for deployment

- [ ] **Step 1: Reload pi to activate the new extension**

Run: `home-manager switch --flake .`

Expected: No errors

- [ ] **Step 2: Test 1 — Code file search (should route to fd with project scope)**

Run: `pi -c "find . -name '*.ts' -type f"`

Expected: 
- Output lists TypeScript files
- Console shows "find → fd" routing message
- Search is scoped to project root (not root filesystem)

- [ ] **Step 3: Test 2 — Config file search (should route to fd with home scope)**

Run: `pi -c "find . -name '*.json'"`

Expected:
- Output lists JSON files in project
- Routing message indicates fd
- Completes quickly

- [ ] **Step 4: Test 3 — Reject root search (safety constraint)**

Run: `pi -c "find / -name '*.txt' -type f"`

Expected:
- Error message like "cannot search in system path / for safety/performance reasons"
- No actual search executed

- [ ] **Step 5: Test 4 — Reject /usr search (system directory)**

Run: `pi -c "find /usr -name 'config'"`

Expected:
- Error message blocking /usr path
- Command does not execute

- [ ] **Step 6: Test 5 — General file search (should use fd, CWD only)**

Run: `pi -c "find . -type f"`

Expected:
- Lists files in current directory
- Uses fd routing
- Completes quickly

- [ ] **Step 7: Verify logs**

Check pi session logs or console output for routing messages indicating which tool was used.

Expected: Consistent routing (all to fd, with intent properly detected)

- [ ] **Step 8: Commit test results**

Create a brief test log if needed:

```bash
jj add -m "test: verify intelligent-find extension works in all test cases"
```

---

## Summary

After completing all tasks:

✅ `fd` added to nix packages  
✅ `intelligent-find.ts` extension created with:
- Intent detection (code/config/general)
- Scope detection with safety constraints
- Find command parser
- Find→fd/rg translation
- Tool override registration
- Error handling for unsafe searches  
✅ All tests passing  
✅ Safe from root-level searches  
✅ Performance improved via fd/rg

**Ready for verification before completion.**
