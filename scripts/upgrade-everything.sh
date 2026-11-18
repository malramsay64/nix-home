# Sourced into a writeShellApplication by shared.nix, which first defines:
#   profile             home-manager profile name ("home" or "work")
#   npx_mcp_packages    npm packages of the one-shot (npx) MCP servers
#   uvx_mcp_packages    PyPI packages of the one-shot (uvx) MCP servers

find_flake_dir() {
  local candidate
  for candidate in "${NIX_HOME_FLAKE:-}" "$HOME/Projects/nix-home" "$HOME/projects/nix-home"; do
    if [[ -n "$candidate" && -f "$candidate/flake.nix" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

if ! flake_dir="$(find_flake_dir)"; then
  echo "Nix Home flake directory not found in ~/Projects/nix-home or ~/projects/nix-home." >&2
  echo "Set NIX_HOME_FLAKE to the checkout directory and retry." >&2
  exit 2
fi

failures=()
run_step() {
  local name="$1"
  shift
  printf '\n==> %s\n' "$name"
  if "$@"; then
    printf '    completed: %s\n' "$name"
  else
    local status=$?
    printf '    FAILED (%s): %s\n' "$status" "$name" >&2
    failures+=("$name")
  fi
}

upgrade_apt() {
  /usr/bin/sudo apt-get update && /usr/bin/sudo apt-get upgrade -y
}

upgrade_winget() {
  winget.exe upgrade --all --accept-source-agreements --accept-package-agreements
}

open_windows_update() {
  powershell.exe -NoProfile -Command "Start-Process 'ms-settings:windowsupdate'"
}

upgrade_uv_tools() {
  uv tool upgrade --all
  uv python upgrade
}

upgrade_pi_extensions() {
  pi update --extensions
}

refresh_mcp_tool_caches() {
  local entry key pkg
  if (( ${#npx_mcp_packages[@]} )); then
    while IFS= read -r entry; do
      key="${entry%%:*}"
      [[ "$key" =~ ^[[:xdigit:]]+$ ]] || continue
      for pkg in "${npx_mcp_packages[@]}"; do
        if [[ "$entry" == *"$pkg"* ]]; then
          npm cache npx rm "$key" || return $?
          break
        fi
      done
    done < <(npm cache npx ls)
  fi

  # `uv cache clean` with no arguments would wipe the whole cache.
  if (( ${#uvx_mcp_packages[@]} )); then
    uv cache clean "${uvx_mcp_packages[@]}"
  fi
}

upgrade_determinate_nix() {
  if command -v determinate-nixd >/dev/null 2>&1; then
    /usr/bin/sudo "$(command -v nix)" upgrade-nix
  else
    echo "Determinate Nix not detected; skipping the Nix installation upgrade."
  fi
}

upgrade_nix_and_home_manager() {
  (cd "$flake_dir" && nix flake update) &&
    home-manager switch --flake "$flake_dir#$profile"
}

# Keep 7 days of generations so a recent switch can still be rolled back,
# then delete everything in the store no longer reachable from a profile.
collect_garbage() {
  home-manager expire-generations "-7 days" &&
    nix-collect-garbage --delete-older-than 7d
}

clean_caches() {
  uv cache prune
  npm cache verify
}

if [[ "$profile" == "work" ]]; then
  run_step "Ubuntu system packages (apt)" upgrade_apt
  run_step "Windows packages (winget)" upgrade_winget
  run_step "Open Windows Update settings" open_windows_update
fi
run_step "uv tools" upgrade_uv_tools
run_step "Pi packages" upgrade_pi_extensions
run_step "Refresh one-shot MCP tool caches" refresh_mcp_tool_caches
run_step "Determinate Nix installation" upgrade_determinate_nix
run_step "Nix flake inputs and Home Manager" upgrade_nix_and_home_manager
run_step "Nix garbage collection (older than 7 days)" collect_garbage
run_step "uv and npm cache cleanup" clean_caches

if (( ${#failures[@]} )); then
  printf '\nUpgrade finished with failures: %s\n' "${failures[*]}" >&2
  exit 1
fi
printf '\nAll upgrades completed successfully.\n'
