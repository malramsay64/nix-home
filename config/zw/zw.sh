# zw: one zellij session per git worktree, with worktrunk (`wt`) doing the git
# side. Run `zw help` for the flight rules.
#
# Environment overrides (used for testing):
#   ZW_PROJECTS    file listing project repo paths, one per line
#   ZW_LAYOUT_DIR  directory holding worktree.kdl and worktree-lazy.kdl

projects_file=${ZW_PROJECTS:-$HOME/.config/zw/projects}
help_file=${ZW_HELP:-$HOME/.config/zw/help.md}

die() {
  echo "zw: $*" >&2
  exit 1
}

confirm() {
  local reply
  read -r -p "$1 [y/N] " reply
  [[ $reply == y || $reply == Y ]]
}

pause() {
  read -r -n1 -s -p "Press any key to close" || true
}

layout_arg() {
  if [[ -n ${ZW_LAYOUT_DIR:-} ]]; then
    echo "$ZW_LAYOUT_DIR/$1.kdl"
  else
    echo "$1"
  fi
}

# `Ctrl g o n` and friends run zw in a floating pane; zellij is already running.
in_zellij() {
  [[ -n ${ZELLIJ:-} ]]
}

project_list() {
  [[ -r $projects_file ]] || die "no project list at $projects_file"
  local line
  while IFS= read -r line; do
    [[ -z $line || $line == \#* ]] && continue
    echo "${line/#\~/$HOME}"
  done <"$projects_file"
}

# The main checkout of the repository containing $1 (a worktree or the repo).
main_repo() {
  local common
  common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  dirname "$common"
}

session_name() {
  local repo=$1 branch=$2
  printf '%s.%s' "$(basename "$repo")" "$(printf '%s' "$branch" | tr -c 'A-Za-z0-9._-' '-')"
}

session_exists() {
  zellij list-sessions --short 2>/dev/null | grep -Fxq "$1"
}

current_session() {
  echo "${ZELLIJ_SESSION_NAME:-}"
}

# Pick the project for this command: the repo we are standing in, else ask.
pick_project() {
  local repo
  if repo=$(main_repo "$PWD"); then
    echo "$repo"
    return
  fi
  project_list | fzf --prompt="project> " --height=40% --reverse
}

# branch<TAB>path<TAB>main|""<TAB>dirty|clean for every worktree of a repo.
worktrees_of() {
  wt -C "$1" list --format json | jq -r '
    .items[]
    | select(.worktree != null and (.worktree.prunable // false) == false)
    | [ (.branch // "(detached)"),
        .worktree.path,
        (if .worktree.main then "main" else "" end),
        (if ((.worktree.changes // {})
              | [.staged, .modified, .untracked, .renamed, .deleted, .conflicted] | any)
         then "dirty" else "clean" end) ]
    | @tsv'
}

# Create a session without attaching: zellij only builds a layout for a
# connected client, so run one in a throwaway pty and let it hang up.
create_detached() {
  local name=$1 dir=$2 layout=$3 i
  (
    cd "$dir" || die "no such directory: $dir"
    sleep 6 | env -u ZELLIJ -u ZELLIJ_SESSION_NAME -u ZELLIJ_PANE_ID \
      setsid script -qfc "stty cols 200 rows 50; zellij --session $name --new-session-with-layout $layout" /dev/null \
      >/dev/null 2>&1 &
  )
  for ((i = 0; i < 30; i++)); do
    session_exists "$name" && return 0
    sleep 0.5
  done
  die "session $name did not start"
}

# Go to a worktree's session, creating it from the full layout if needed.
open_session() {
  local name=$1 dir=$2
  if in_zellij; then
    if session_exists "$name"; then
      zellij action switch-session "$name"
    else
      zellij action switch-session "$name" --layout "$(layout_arg worktree)" --cwd "$dir"
    fi
  elif session_exists "$name"; then
    exec zellij attach "$name"
  else
    cd "$dir" || die "no such directory: $dir"
    exec zellij --session "$name" --new-session-with-layout "$(layout_arg worktree)"
  fi
}

# Get out of session $1 before it is deleted, if we are standing in it.
leave_session() {
  [[ $(current_session) == "$1" ]] || return 0
  zellij action go-to-previous-session || zellij action go-to-next-session || true
}

drop_session() {
  session_exists "$1" || return 0
  zellij delete-session --force "$1" >/dev/null 2>&1 || true
}

cmd_new() {
  local branch=${1:-} base=${2:-} repo out path create=(--create)
  repo=$(pick_project) || die "no project chosen"
  if [[ -z $branch ]]; then
    read -r -p "new branch in $(basename "$repo"): " branch
  fi
  [[ -n $branch ]] || die "no branch given"
  if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
    create=()
  fi
  out=$(wt -C "$repo" switch "${create[@]}" ${base:+--base "$base"} --no-cd --format json "$branch") \
    || die "wt could not create $branch"
  path=$(jq -r '.path' <<<"$out")
  open_session "$(session_name "$repo" "$branch")" "$path"
}

# Pick any worktree of any project and go to its session.
cmd_open() {
  local repo line branch path name state rows="" choice
  while IFS= read -r repo; do
    [[ -d $repo ]] || continue
    while IFS=$'\t' read -r branch path _ _; do
      name=$(session_name "$repo" "$branch")
      state=closed
      session_exists "$name" && state=open
      rows+="$name"$'\t'"$state"$'\t'"$path"$'\n'
    done < <(worktrees_of "$repo")
  done < <(project_list)
  [[ -n $rows ]] || die "no worktrees found"
  choice=$(printf '%s' "$rows" | column -t -s $'\t' | fzf --prompt="worktree> " --height=40% --reverse) \
    || return 0
  line=$(awk '{print $1 "\t" $3}' <<<"$choice")
  open_session "${line%%$'\t'*}" "${line##*$'\t'}"
}

# Every worktree of every project gets a session; existing ones are left alone.
cmd_up() {
  local repo branch path name made=0
  while IFS= read -r repo; do
    [[ -d $repo ]] || { echo "skip $repo (missing)"; continue; }
    while IFS=$'\t' read -r branch path _ _; do
      name=$(session_name "$repo" "$branch")
      if session_exists "$name"; then
        continue
      fi
      echo "creating $name"
      create_detached "$name" "$path" "$(layout_arg worktree-lazy)"
      made=$((made + 1))
    done < <(worktrees_of "$repo")
  done < <(project_list)
  echo "$made session(s) created"
}

cmd_rm() {
  local repo flags=() arg branch="" path name rows choice
  for arg in "$@"; do
    case $arg in
      --force | -f) flags+=(--force) ;;
      -D) flags+=(-D) ;;
      *) branch=$arg ;;
    esac
  done
  repo=$(pick_project) || die "no project chosen"
  if [[ -z $branch ]]; then
    rows=$(worktrees_of "$repo" | awk -F'\t' '$3 != "main" {print $1 "\t" $4 "\t" $2}' | column -t -s $'\t')
    [[ -n $rows ]] || die "no removable worktrees in $(basename "$repo")"
    choice=$(fzf --prompt="remove> " --height=40% --reverse <<<"$rows") || return 0
    branch=$(awk '{print $1}' <<<"$choice")
  fi
  name=$(session_name "$repo" "$branch")
  confirm "Remove worktree $branch and session $name?" || return 0
  leave_session "$name"
  if wt -C "$repo" remove "$branch" --foreground --yes "${flags[@]}"; then
    drop_session "$name"
  else
    echo "zw: worktree not removed (dirty or unmerged? see --force / -D)" >&2
    pause
    return 1
  fi
}

# Land the current worktree with `wt merge`, then remove its session.
cmd_merge() {
  local repo branch name
  repo=$(main_repo "$PWD") || die "not in a git repository"
  branch=$(git branch --show-current)
  [[ -n $branch ]] || die "detached HEAD"
  name=$(session_name "$repo" "$branch")
  wt merge || {
    pause
    return 1
  }
  cd "$repo" || return 1
  leave_session "$name"
  drop_session "$name"
}

cmd_status() {
  local repo
  repo=$(pick_project) || die "no project chosen"
  wt -C "$repo" list --full 2>/dev/null || wt -C "$repo" list
  pause
}

cmd_help() {
  if [[ -r $help_file ]]; then
    "${PAGER:-less}" "$help_file"
  else
    die "no help file at $help_file"
  fi
}

usage() {
  cat <<'EOF'
usage: zw [command]
  (none) | open   pick a worktree and go to its session
  new [branch] [base]
                  create a worktree + session and go there
  up              create sessions for every worktree that lacks one
  rm [branch] [--force] [-D]
                  remove a worktree and its session
  merge           wt merge the current worktree, then remove its session
  status          wt list for a project
  help            flight rules
EOF
}

cmd=${1:-open}
shift || true
case $cmd in
  open) cmd_open ;;
  new) cmd_new "$@" ;;
  up) cmd_up ;;
  rm) cmd_rm "$@" ;;
  merge) cmd_merge ;;
  status) cmd_status ;;
  help | -h | --help) cmd_help ;;
  *) usage >&2; exit 2 ;;
esac
