#!/bin/sh
# Left 65%: editor (top) over shell (bottom). Right 35%: Claude Code.
set -eu
h="${HERDR_BIN_PATH:-herdr}"
editor=$(command -v ms >/dev/null 2>&1 && echo ms || echo hx)

id() { sed -n 's/.*"pane_id":"\([^"]*\)".*/\1/p'; }

editor_pane="$HERDR_PANE_ID"
claude_pane=$("$h" pane split "$editor_pane" --direction right --ratio 0.65 | id)
shell_pane=$("$h" pane split "$editor_pane" --direction down --ratio 0.7 | id)

"$h" pane run "$claude_pane" claude
"$h" pane run "$editor_pane" "$editor ."
"$h" pane focus "$editor_pane" >/dev/null 2>&1 || true
