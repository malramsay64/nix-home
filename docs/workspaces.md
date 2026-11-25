# Worktree workspaces (zellij + worktrunk)

One zellij session per git worktree, named `<repo>.<branch>`. Every session has
the same two tabs:

- `dev`: `ms .` over a shell on the left 70%, `claude` on the right 30%.
- `servers`: two shells side by side for long-running tasks.

`wt` (worktrunk) does the git side, `zw` ties it to zellij. Worktrees live in
`~/.worktrees/<repo>/<branch>`. The projects `zw` knows about are listed in
`zw.projects` in `home.nix` / `work.nix` (generated to `~/.config/zw/projects`).

## Keys

Zellij starts locked. `Ctrl g` unlocks into normal mode, `o` opens session
mode, and the status bar lists the keys that mode offers. The worktree actions
run in a floating pane, so they are not named in the status bar; they are
here instead (`zw help` shows this page).

| Keys | Action |
|---|---|
| `Alt w` | session list: every worktree, running or exited |
| `Alt p` | previous session |
| `Alt a` | next pane that needs attention, in any session |
| `Alt g` | gitui for the current worktree |
| `Ctrl g o n` | new worktree (`zw new`) |
| `Ctrl g o x` | remove worktree and session (`zw rm`) |
| `Ctrl g o g` | merge worktree into the default branch (`zw merge`) |
| `Ctrl g o i` | status of the project's worktrees (`zw status`) |
| `Ctrl g o u` | create sessions for worktrees that lack one (`zw up`) |
| `Ctrl g o h` | this page |
| `Ctrl g o d` | detach |

## Flight rules

**Start of day, or after a reboot**

1. Run `zellij`. `Alt w` lists every session; ones that were running before
   the reboot show as EXITED.
2. Run `zw up` to create sessions for any worktree that has none.
3. Pick a session and press Enter. EXITED ones resurrect with their layout and
   directories. Panes that ran `ms` or `claude` wait for Enter before starting.

**New feature worktree**: `Ctrl g o n` (or `zw new [branch] [base]`), choose
the project if you are not inside one, type the branch name. You land in the
new session with the editor, a shell and Claude running.

**Switch worktree**: `Alt w`, type to filter, Enter. `Alt p` goes back.
`zw` with no arguments is a fuzzy picker over every worktree of every project,
including ones with no session yet.

**What changed, and where**: `Ctrl g o i` shows each worktree's state
(`wt list`), `Alt g` opens gitui in the current one, and `Alt w` previews other
sessions without switching. `Alt a` jumps to whichever Claude is waiting on
you.

**Finish a feature**

- Merged on GitHub: `Ctrl g o x`, pick the worktree, confirm. The worktree,
  its branch (if merged) and the session go.
- Landing locally: `Ctrl g o g` runs `wt merge` (squash, rebase, fast-forward),
  then removes the worktree, branch and session.

**Abandon a worktree with uncommitted work**: `zw rm` refuses. Commit or stash,
or `zw rm --force <branch>`. Force saves the changes to `refs/wt-backup/<branch>`
and prints the command to recover them. An unmerged branch is kept unless you
also pass `-D`.

**A worktree was removed outside `zw`** (`rm -rf`, `git worktree remove`):
`git worktree prune`, then `zellij delete-session <name>`, otherwise it lingers
as EXITED. `wt remove` run directly is fine; a hook deletes the session.

**An EXITED session you no longer want**: in `Alt w`, select it and delete it.
This never touches the worktree.

**Frozen pane or session**: `Alt w`, kill the session, select it again to
resurrect from the last snapshot (at most a minute old).

**Worktree made with plain `git` or `wt`**: `zw up` picks it up.

**Add a project**: add its path to `zw.projects` in that profile's file (`home.nix` or `work.nix`), `home-manager switch`, then
`zw up`.

**Leave everything running**: `Ctrl g o d`. Come back with `zellij`, then
`Alt w`.
