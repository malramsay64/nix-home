# Herdr-style Zellij: one session per git worktree (opened from lazyworktree
# with `Z`), each started from layouts/worktree.kdl, with a project sidebar in
# every tab that shows live Claude Code status.
{
  pkgs,
  config,
  ...
}:
let
  home = config.home.homeDirectory;
  zellij = config.programs.zellij.package;
  wasmLd = "${pkgs.buildPackages.lld}/bin/wasm-ld";

  # The layout every worktree session starts from; also used by the sidebar
  # when it starts a session for a project.
  worktreeLayout = "${home}/.config/zellij/layouts/worktree.kdl";
  # The sidebar's own Super+t "new tab" layout hardcodes this location.
  sidebarUrl = "file:~/.config/zellij/plugins/zellij-project-sidebar.wasm";

  sidebarSrc = pkgs.fetchFromGitHub {
    owner = "AndrewBeniston";
    repo = "zellij-project-sidebar";
    rev = "b62fdcd638f5ed50a974ac082f0044c87f06c658";
    hash = "sha256-3mQk/kDdaS9hFL/cHpYACQdPEQwUgABf0/X6vkYENe0=";
  };

  # No releases are published; the README's install is
  # `cargo build --target wasm32-wasip1 --release`, done here with the
  # wasm32-wasip1 cross toolchain from nixpkgs. That toolchain links through
  # clang, which rejects the lld-style flags rustc passes for wasm, and the
  # build hook sets the linker env var inline, so link with wasm-ld via
  # target-only rustflags instead.
  sidebarPlugin = pkgs.pkgsCross.wasi32.rustPlatform.buildRustPackage {
    pname = "zellij-project-sidebar";
    version = "0.1.0-unstable-2026-03-15";
    src = sidebarSrc;
    cargoHash = "sha256-eDJw2g7uNvMOCbGQJ+MbaqyQgBUQ4+zlDHyPcOgX57E=";
    CARGO_TARGET_WASM32_WASIP1_RUSTFLAGS = "-C linker=${wasmLd}";
    doCheck = false;
  };

  sidebarPane = ''
    pane size=30 name="Projects" {
        plugin location="${sidebarUrl}" {
            scan_dir "${home}/Projects"
            session_layout "${worktreeLayout}"
        }
    }
  '';

  # Create or attach to a worktree's session using the worktree layout.
  # lazyworktree's built-in zellij support builds one tab per window and
  # can't take a layout file, so `Z` runs this instead.
  zellijWorktree = pkgs.writeShellApplication {
    name = "zellij-worktree";
    runtimeInputs = [ zellij ];
    text = ''
      if [ $# -ne 2 ]; then
        echo "usage: zellij-worktree <session-name> <worktree-path>" >&2
        exit 2
      fi
      # Zellij rejects these in session names; lazyworktree replaces them too.
      session=$(printf '%s' "$1" | tr '/\\:' '---')
      dir=$2

      if [ -n "''${ZELLIJ:-}" ]; then
        # Already inside Zellij: switch this client over, creating the session
        # from the layout if it isn't running.
        exec zellij action switch-session "$session" --layout worktree --cwd "$dir"
      fi

      if zellij list-sessions --short 2>/dev/null | grep -Fxq "$session"; then
        exec zellij attach "$session"
      fi
      cd "$dir"
      exec zellij --session "$session" --new-session-with-layout worktree
    '';
  };

in
{
  home.packages = [ zellijWorktree ];

  programs.lazygit.enable = true;

  programs.lazyworktree = {
    enable = true;
    settings = {
      session_prefix = "wt-";
      custom_commands.universal.Z = {
        description = "Zellij (worktree layout)";
        show_help = true;
        command = ''zellij-worktree "wt-$WORKTREE_NAME" "$WORKTREE_PATH"'';
      };
    };
  };

  xdg.configFile = {
    "zellij/plugins/zellij-project-sidebar.wasm".source =
      "${sidebarPlugin}/bin/zellij-project-sidebar.wasm";

    # Sidebar fixed at 30 columns in every tab, Claude in the main area, a
    # shell over lazygit on the right, compact bar below. New tabs need their
    # own template: from default_tab_template, `children` gets no terminal,
    # and since the sidebar marks itself unselectable Zellij closes the tab
    # straight away.
    "zellij/layouts/worktree.kdl".text = ''
      layout {
          default_tab_template {
              pane split_direction="vertical" {
                  ${sidebarPane}
                  children
              }
              pane size=1 borderless=true {
                  plugin location="compact-bar"
              }
          }
          new_tab_template {
              pane split_direction="vertical" {
                  ${sidebarPane}
                  pane
              }
              pane size=1 borderless=true {
                  plugin location="compact-bar"
              }
          }
          tab name="main" focus=true {
              pane split_direction="vertical" {
                  pane size="70%" name="claude" command="claude" focus=true
                  pane split_direction="horizontal" {
                      pane name="shell"
                      pane name="lazygit" command="lazygit"
                  }
              }
          }
      }
    '';
  };

  # Live AI status in the sidebar (README "Setting up Claude Code hooks").
  # The script exits immediately outside Zellij.
  home.file.".claude/hooks/sidebar-status.sh".source = "${sidebarSrc}/scripts/sidebar-status.sh";
  programs.claude-code.settings.hooks =
    let
      sidebarHook = [
        {
          hooks = [
            {
              type = "command";
              command = "$HOME/.claude/hooks/sidebar-status.sh";
              async = true;
            }
          ];
        }
      ];
    in
    {
      PostToolUse = sidebarHook;
      Stop = sidebarHook;
      Notification = sidebarHook;
      SessionStart = sidebarHook;
    };
}
