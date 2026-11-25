# Herdr-style workspaces on stock Zellij: one session per git worktree,
# started from layouts/worktree.kdl. worktrunk (`wt`) manages the worktrees and
# `zw` (config/zw/zw.sh) ties them to sessions. See docs/workspaces.md.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  home = config.home.homeDirectory;
  zellij = config.programs.zellij.package;

  zw = pkgs.writeShellApplication {
    name = "zw";
    runtimeInputs = [
      zellij
      pkgs.worktrunk
      pkgs.git
      pkgs.fzf
      pkgs.jq
      pkgs.util-linux # script(1), for creating sessions without a terminal
      pkgs.gawk
      pkgs.less
    ];
    text = builtins.readFile ./config/zw/zw.sh;
  };

  # `lazy` panes wait for Enter before starting, so recreating a session for
  # every worktree after a reboot doesn't launch an editor and a Claude each.
  layout =
    { lazy }:
    let
      suspended = if lazy then "\n                    start_suspended true" else "";
      claudeBody = if lazy then " {\n                    start_suspended true\n                  }" else "";
    in
    ''
      layout {
          default_tab_template {
              pane size=1 borderless=true {
                  plugin location="tab-bar"
              }
              children
              pane size=1 borderless=true {
                  plugin location="status-bar"
              }
          }
          new_tab_template {
              pane size=1 borderless=true {
                  plugin location="tab-bar"
              }
              pane
              pane size=1 borderless=true {
                  plugin location="status-bar"
              }
          }
          // dev: editor over a shell on the left 70%, Claude on the right 30%.
          tab name="dev" focus=true {
              pane split_direction="vertical" {
                  pane size="70%" split_direction="horizontal" {
                      pane name="editor" command="ms" size="65%" focus=true {
                          args "."${suspended}
                      }
                      pane name="shell" size="35%"
                  }
                  pane name="claude" command="claude" size="30%"${claudeBody}
              }
          }
          // servers: two shells side by side for long-running tasks.
          tab name="servers" {
              pane split_direction="vertical" {
                  pane name="server-1"
                  pane name="server-2"
              }
          }
      }
    '';
in
{
  options.zw.projects = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "/home/me/Projects/app" ];
    description = ''
      Repositories zw manages worktree sessions for, set per profile.
      Worktrees themselves are discovered dynamically.
    '';
  };

  config.home.packages = [
    zw
    pkgs.worktrunk
  ];

  config.xdg.configFile = {
    "zellij/layouts/worktree.kdl".text = layout { lazy = false; };
    "zellij/layouts/worktree-lazy.kdl".text = layout { lazy = true; };

    "zw/projects".text = builtins.concatStringsSep "\n" config.zw.projects + "\n";
    "zw/help.md".source = ./docs/workspaces.md;

    "worktrunk/config.toml".text = ''
      worktree-path = "~/.worktrees/{{ repo }}/{{ branch | sanitize }}"

      # A plain `wt remove` must not leave an orphan session behind.
      post-remove = "zellij delete-session --force '{{ repo }}.{{ branch | sanitize }}' >/dev/null 2>&1 || true"
    '';
  };
}
