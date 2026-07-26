# Global Agent Instructions

## Version control

This user manages source control with [Jujutsu (`jj`)](https://jj-vcs.github.io/jj/),
not raw `git`, even in repositories that are backed by a git store.

- Use `jj` commands for all version control operations: creating commits,
  viewing status/diffs/log, branching, and pushing.
- To record work, use `jj commit -m "..."` (or `jj describe -m "..."` on the
  current change followed by `jj new`), not `git commit`.
- Use `jj st` / `jj diff` / `jj log` instead of `git status` / `git diff` /
  `git log`.
- Only fall back to `git` directly if `jj` is unavailable in the repository,
  or the user explicitly asks for a raw git command.
