# Intelligent Find Replacement Design Spec

**Date:** 2025-01-28  
**Author:** Pi Agent with User Input  
**Status:** Approved Design

## Overview

Replace Pi's built-in `find` tool with a smart wrapper that routes file searches to `rg` (ripgrep) or `fd` based on search intent and automatically scopes searches to safe directories. This addresses two core concerns:

1. **Performance** — Ripgrep and fd are significantly faster than find, especially for code/config searches
2. **Safety** — Prevent accidental root-level filesystem traversals that are slow, resource-intensive, and often unintended

## Problem Statement

The built-in `find` tool allows searches from any directory, including the filesystem root (`/`). This creates two issues:

1. **Performance burden** — Searching from `/` on the entire filesystem is slow and resource-intensive, often blocking agent execution
2. **Safety risk** — Root searches are rarely intentional and often happen when directory scoping is overlooked

The user manages tools via Nix (ripgrep, fd, jq, etc.) and wants the Pi agent to use them intelligently rather than falling back to slower alternatives.

## Solution Architecture

### 1. Tool Routing Logic

Analyze search queries to determine the best tool:

| Search Type | Tool | Rationale |
|---|---|---|
| Content search (grepping inside files) | `rg` | Ripgrep is optimized for code/text search, respects `.gitignore`, much faster than find |
| File-by-name search | `fd` | Fd is a faster find alternative with cleaner syntax |
| Pattern matching + file extension | `fd` | Fd's type-based filtering is more efficient than find |

**Detection heuristics:**
- If query includes text content to find (e.g., `-type f -exec grep ...`) → use `rg`
- If query is file-name/extension pattern (e.g., `-name "*.rs"` or `-type f`) → use `fd`
- If truly ambiguous, default to `fd` (file-discovery is safer than guessing content search)

### 2. Directory Scoping

Automatically determine safe search boundaries based on file type intent:

| Intent | Primary Scope | Secondary Scopes | Excluded |
|---|---|---|---|
| **Code files** (.ts, .rs, .js, .py, .go, .nix, .java, .cpp, etc.) | Current working directory | Parent directories containing `.git`, `.jj`, `flake.nix` (up to 5 levels) | System directories |
| **Config files** (.json, .yaml, .toml, .ini, .config, dotfiles) | CWD + home directory config | `~/.config`, `~/.local`, project-specific config dirs | System config dirs like `/etc` |
| **General files** (no extension or unknown) | Current working directory only | None | Everything outside CWD |
| **Root-level searches** | REJECT | N/A | Always blocked with clear error |

**Scope detection algorithm:**
1. Examine file patterns/extensions in the search query
2. Match against known code/config file patterns
3. Return the appropriate scope boundaries
4. If CWD is already within home or project, use it as base; don't traverse upward to root

### 3. Constraints & Safety

Hard constraints that cannot be overridden:

1. **Never search from `/`** — Reject any search attempt starting at filesystem root
2. **Never search system directories** — Exclude `/usr`, `/opt`, `/nix/store`, `/etc` (except for config files explicitly in home)
3. **Require explicit scope** — If scope cannot be determined from the search pattern, error loudly rather than guess
4. **Respect user's Nix setup** — Use ripgrep and fd as managed by `pi.nix`'s `extraPackages`

### 4. Implementation Details

**Extension: `pi/extensions/intelligent-find.ts`**

This Pi extension will:

1. Hook into the `tool_call` event for `find` tool invocations
2. Parse the find command (extract directory, patterns, file types)
3. Determine search intent (code, config, general)
4. Calculate safe scope boundaries
5. Translate the find command to `rg` or `fd` syntax
6. Execute the faster alternative
7. Log the translation for transparency ("Routing to fd with scope /home/malcolm/projects/...")

**Tool signature:**
```
find(startPath, patterns, options) → returns file paths or error
```

**Behavior:**
- If `startPath` is `/` or starts with `/usr`, `/opt`, `/nix/store`, reject immediately with clear error
- If `startPath` is within `$HOME` or current workspace, proceed with scope calculation
- Parse patterns to detect intent (code file extensions, config patterns, etc.)
- Calculate safe scope: CWD ± identified project root or config directories
- Translate find syntax to `rg` (for content) or `fd` (for file discovery)
- Return results in compatible format (one file per line, preserving find output style)

**Error messages:**
- "find: root directory searches blocked for safety/performance — use rg/fd in a scoped directory"
- "find: cannot determine safe scope from search pattern — specify file type or use rg/fd directly"

### 5. Configuration

**In `pi.nix`:**
- Ensure `ripgrep` and `fd` are in `extraPackages` (already present: ripgrep is there)
- Add `fd` package if not already present
- Reference the intelligent-find extension in `settings.extensions`

**In `pi/extensions/intelligent-find.ts`:**
- Define code file extensions: `['.ts', '.rs', '.js', '.py', '.go', '.nix', '.java', '.cpp', '.c', '.h', '.swift', '.kt', '.scala', '.clj', '.rb', '.sh']`
- Define config file patterns: `['.json', '.yaml', '.yml', '.toml', '.ini', '.*rc', '.env', '.config', '.conf']`
- Define project markers: `['.git', '.jj', 'flake.nix', 'package.json', 'Cargo.toml', 'pyproject.toml']`
- Implement scope detection (walk up from CWD until project marker found or home dir reached)
- Implement find → fd/rg translation logic
- Add logging/transparency so user sees which tool was chosen

## Testing Strategy

1. **Unit tests in extension** — Mock find queries, verify correct tool selection
2. **Integration tests** — Run actual find/rg/fd commands in test directories
3. **Safety tests** — Verify root searches are rejected, system dirs are blocked
4. **Performance baseline** — Compare find vs. rg/fd on same query in actual project

## Success Criteria

- [x] Root-level searches are rejected with clear error
- [x] Code file searches route to `fd` or `rg` and complete faster than find
- [x] Config file searches respect home directory scoping
- [x] Agent can locate files in projects without root traversals
- [x] Extension logs which tool was chosen for transparency
- [x] No breaking changes to Pi agent functionality

## Out of Scope

- User-facing escape hatch to override scope constraints (safety is non-negotiable)
- Support for searching outside home directory and common project roots
- Changes to other tools (ls, grep, etc.)

## Rollback Plan

If the intelligent-find extension causes issues:
1. Disable via `settings.extensions` in `pi.nix`
2. Comment out the line, rebuild, fall back to built-in find
3. Built-in find remains functional as backup
