# Global Agent Instructions

## Version control

Use `git` for all version control operations: viewing status/diffs/log,
creating commits, branching, and pushing. Don't use `jj`, even in
repositories that have a `.jj` directory, unless the user asks for it.

- Commit or push only when the user asks. If on the default branch, create a
  branch first.
- Stage specific files (`git add <path>`) rather than `git add -A`, so
  unrelated changes aren't swept into a commit.
- Use non-interactive commands; interactive flags such as `git rebase -i` and
  `git add -p` don't work in this environment.
- On a branch other than the default branch, you may tidy its history
  (amend, fixup, squash, reorder with a non-interactive rebase, and
  `git push --force-with-lease`), but confirm with the user before each
  rewrite. Never rewrite history on the default branch.

All commits must follow Conventional Commits 1.0.0:
`<type>(<optional scope>): <description>`, with an optional body and footers.
Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
Use `!` after the type/scope or a `BREAKING CHANGE:` footer for breaking changes.
Write the description in the imperative mood, lowercase, no trailing period.

## Context usage

- Delegate broad codebase searches, large file reads, and exploratory
  investigation to a subagent (`subagent` tool), and have it report back only
  the conclusions and relevant file paths/line numbers.
- Read files in targeted ranges rather than whole when only part is needed.

## Subagents

`pi-subagents` is available for delegated work. When I explicitly ask you to
use subagents, you can use its built-in `scout`, `worker`, `reviewer`, and
`oracle` agents, or ask me which role I want. Keep assignments narrow and
report their results; do not delegate merely because a task is large or
complex unless I ask for delegation.
