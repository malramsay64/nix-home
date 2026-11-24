{
  pkgs,
  lib,
  availableSkills,
  user,
  profile,
  config,
  ...
}:
let
  atuinHook = {
    matcher = "Bash";
    hooks = [
      {
        type = "command";
        command = "atuin hook claude-code";
        timeout = 5;
      }
    ];
  };

  # Language servers and formatters used by helix, mitos and Claude Code
  # (see config/languages.toml and programs.claude-code.lspServers).
  editorTools = [
    pkgs.bash-language-server
    pkgs.docker-compose-language-service
    pkgs.dockerfile-language-server
    pkgs.nixd
    pkgs.terraform-ls
    pkgs.taplo
    pkgs.marksman
    pkgs.tinymist
    pkgs.shellcheck
    pkgs.yaml-language-server
    pkgs.rust-analyzer
    pkgs.typos-lsp
    pkgs.harper
    pkgs.ruff
    pkgs.prettierd
    pkgs.omnisharp-roslyn
    pkgs.ty
    pkgs.zizmor
  ];

  # Package names of the one-shot MCP servers started through `launcher`
  # (npx/uvx, possibly behind `op run`), with any @version suffix removed, so
  # upgrade-everything can drop their cached copies.
  mcpPackages =
    launcher:
    lib.unique (
      lib.concatMap (
        server:
        let
          argv = [ (server.command or "") ] ++ (server.args or [ ]);
          idx = lib.lists.findFirstIndex (arg: arg == launcher) null argv;
          rest = if idx == null then [ ] else lib.filter (arg: !lib.hasPrefix "-" arg) (lib.drop (idx + 1) argv);
        in
        lib.optional (rest != [ ]) (lib.head (builtins.match "(@?[^@]+)(@.*)?" (lib.head rest)))
      ) (lib.attrValues config.pi.mcpServers)
    );

  upgradeEverything = pkgs.writeShellApplication {
    name = "upgrade-everything";
    runtimeInputs = [
      pkgs.nix
      pkgs.uv
      pkgs.nodejs
      config.programs.pi-coding-agent.package
    ];
    text = ''
      profile=${lib.escapeShellArg profile}
      npx_mcp_packages=(${lib.escapeShellArgs (mcpPackages "npx")})
      uvx_mcp_packages=(${lib.escapeShellArgs (mcpPackages "uvx")})
    ''
    + builtins.readFile ./scripts/upgrade-everything.sh;
  };

  # The hook script `herdr integration install claude` writes, generated at
  # build time so it tracks the installed herdr version. The installer also
  # edits settings.json, which is nix-managed, so it runs against a scratch
  # HOME and only the script is kept; the matching hook entry lives in
  # programs.claude-code.settings below.
  herdrClaudeHook =
    pkgs.runCommand "herdr-claude-hook" { nativeBuildInputs = [ config.programs.herdr.package ]; }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME/.claude"
        herdr integration install claude
        install -Dm755 "$HOME/.claude/hooks/herdr-agent-state.sh" "$out"
      '';
in
{
  home.username = user.username;
  home.homeDirectory = user.home;

  # Don't change this, even when updating Home Manager, without first checking
  # the Home Manager release notes.
  home.stateVersion = "24.11";

  home.packages =
    with pkgs;
    [
      upgradeEverything

      # Core Tools
      iosevka
      duckdb
      typst
      lazyjj
      tree
      just
      mitos
      dust
      hyperfine
      pqrs
      nixfmt
      mermaid-cli
      prettier
      prettier-plugin-jinja-template
      nodejs
      exiftool
      betterleaks
      prek
    ]
    ++ editorTools;
  fonts.fontconfig.enable = true;

  home.file = {
    ".config/helix/config.toml".source = config/helix/config.toml;
    ".config/helix/languages.toml".source = config/languages.toml;
    ".config/mitos/config.toml".source = config/mitos/config.toml;
    ".config/mitos/languages.toml".source = config/languages.toml;
    ".config/mitos/runtime/dictionaries/en_AU".source = "${pkgs.hunspellDicts.en_AU}/share/hunspell";
    ".config/zellij/config.kdl".source = config/zellij/config.kdl;
    ".config/herdr/plugins/config/cloudmanic.herdr-plus/worktrees/default.toml".source =
      config/herdr/herdr-plus/worktrees/default.toml;
    ".claude/hooks/herdr-agent-state.sh".source = herdrClaudeHook;
  };

  home.sessionVariables = {
    COLORTERM = "truecolor";
  };

  claude.skills = builtins.attrValues availableSkills."pymc-labs"."pymc-modeling";

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  services.ssh-agent.enable = true;

  programs = {
    # Profile-specific MCP servers are added via programs.claude-code.mcpServers
    # (e.g. in home.nix).
    claude-code = {
      enable = true;
      context = ''
        # Commits

        All commits must follow Conventional Commits 1.0.0:
        `<type>(<optional scope>): <description>`, with an optional body and footers.
        Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
        Use `!` after the type/scope or a `BREAKING CHANGE:` footer for breaking changes.
        Write the description in the imperative mood, lowercase, no trailing period.
      '';
      # Same language servers as helix and mitos (see config/languages.toml
      # and editorTools). The spell/grammar checkers (typos-lsp, harper-ls) and
      # zizmor are omitted: they overlap file types and give an agent little
      # navigation value.
      lspServers = {
        nix = {
          command = "nixd";
          extensionToLanguage.".nix" = "nix";
        };
        bash = {
          command = "bash-language-server";
          args = [ "start" ];
          extensionToLanguage = {
            ".sh" = "shellscript";
            ".bash" = "shellscript";
          };
        };
        dockerfile = {
          command = "docker-langserver";
          args = [ "--stdio" ];
          extensionToLanguage.".dockerfile" = "dockerfile";
        };
        terraform = {
          command = "terraform-ls";
          args = [ "serve" ];
          extensionToLanguage = {
            ".tf" = "terraform";
            ".tfvars" = "terraform-vars";
          };
        };
        toml = {
          command = "taplo";
          args = [
            "lsp"
            "stdio"
          ];
          extensionToLanguage.".toml" = "toml";
        };
        yaml = {
          command = "yaml-language-server";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".yaml" = "yaml";
            ".yml" = "yaml";
          };
        };
        markdown = {
          command = "marksman";
          args = [ "server" ];
          extensionToLanguage = {
            ".md" = "markdown";
            ".markdown" = "markdown";
          };
        };
        rust = {
          command = "rust-analyzer";
          extensionToLanguage.".rs" = "rust";
        };
        typst = {
          command = "tinymist";
          extensionToLanguage.".typ" = "typst";
        };
        csharp = {
          command = "OmniSharp";
          args = [ "-lsp" ];
          extensionToLanguage.".cs" = "csharp";
        };
        python = {
          command = "ty";
          args = [ "server" ];
          extensionToLanguage = {
            ".py" = "python";
            ".pyi" = "python";
          };
        };
      };
      settings = {
        theme = "auto";
        tui = "fullscreen";
        attribution = {
          commit = "";
          pr = "";
        };
        # Reports session state to herdr. The script is linked in via
        # home.file from herdrClaudeHook.
        hooks.SessionStart = [
          {
            matcher = "^(startup|resume|clear|compact|fork)$";
            hooks = [
              {
                type = "command";
                command = "bash \"$HOME/.claude/hooks/herdr-agent-state.sh\" session";
                timeout = 10;
              }
            ];
          }
        ];
        # Atuin's native agent integration (equivalent to
        # `atuin hook install claude-code`, which can't write to the
        # nix-managed settings.json): records each Bash command Claude runs,
        # tagged as an agent, with its exit code and duration.
        hooks.PreToolUse = [ atuinHook ];
        hooks.PostToolUse = [ atuinHook ];
        hooks.PostToolUseFailure = [ atuinHook ];
      };
    };

    herdr = {
      enable = true;
      settings = {
        onboarding = false;

        terminal.new_cwd = "follow"; # new panes/tabs open in the current worktree

        ui = {
          status_indicators = "symbols";
          agent_panel_sort = "priority"; # blocked/needs-input agents float to the top
          prompt_new_tab_name = false; # Zellij-like: no name prompt for new tabs
          pane_borders = "always"; # frame a lone pane too, not just splits
          tab_bar_right = [
            { type = "zoom"; }
            { type = "datetime"; }
          ];
          toast.delivery = "system";
        };

        keys = {
          prefix = "ctrl+b";

          # Worktrees
          new_worktree = "prefix+shift+g"; # new branch + checkout + workspace
          open_worktree = "prefix+shift+o"; # pick an existing checkout
          remove_worktree = "prefix+alt+d"; # git worktree remove (keeps the branch)

          # Zellij-style direct keys (no prefix)
          focus_pane_left = [
            "prefix+h"
            "alt+h"
          ];
          focus_pane_down = [
            "prefix+j"
            "alt+j"
          ];
          focus_pane_up = [
            "prefix+k"
            "alt+k"
          ];
          focus_pane_right = [
            "prefix+l"
            "alt+l"
          ];
          split_vertical = [
            "prefix+v"
            "alt+n"
          ];
          split_horizontal = [
            "prefix+d"
            "prefix+minus"
          ]; # zellij pane mode: d = down
          zoom = [
            "prefix+z"
            "prefix+f"
            "alt+f"
          ]; # zellij pane mode: f = fullscreen
          next_tab = [
            "prefix+n"
            "alt+]"
          ];
          previous_tab = [
            "prefix+p"
            "alt+["
          ];
          next_workspace = "alt+shift+j"; # move between worktrees
          previous_workspace = "alt+shift+k";
          resize_pane_left = "alt+shift+h";
          resize_pane_right = "alt+shift+l";
          move_tab_previous = "alt+i";
          move_tab_next = "alt+o";
          last_pane = "prefix+;";

          indexed.workspaces = "alt"; # alt+1..9 jumps straight to a worktree

          command = [
            {
              key = "prefix+ctrl+g";
              type = "pane";
              command = "gitui";
            }
            # herdr-plus: fuzzy-pick a project template (shown in prefix+?)
            {
              key = "prefix+up";
              type = "plugin_action";
              command = "cloudmanic.herdr-plus.projects";
              description = "herdr-plus: projects";
            }
          ];
        };
      };
    };

    home-manager.enable = true;
    # Profile-specific hosts are added in home.nix and work.nix.
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".AddKeysToAgent = "yes";
    };
    atuin = {
      enable = true;
      enableFishIntegration = true;
    };
    alacritty = {
      enable = true;
      theme = "one_dark";
      settings.font = {
        normal.family = "Iosevka Term";
        size = 14;
      };
    };
    bat.enable = true;
    difftastic = {
      enable = true;
      # `git diff` uses difftastic; `git difftool` is configured too.
      git = {
        enable = true;
        mode = "both";
      };
      jujutsu.enable = true;
    };
    direnv = {
      enable = true;
      config = {
        global = {
          skip_dotenv = false;
        };
      };
    };
    bottom.enable = true;
    eza = {
      enable = true;
      git = true;
    };
    fd.enable = true;
    fish = {
      enable = true;
      generateCompletions = true;
      interactiveShellInit = ''
        COMPLETE=fish jj | source
        if command -q herdr
          herdr completion fish | source
        end
      '';
    };
    gh.enable = true;
    ghostty.enable = true;
    git = {
      enable = true;
      signing.format = null;
      settings = {
        user.email = user.email;
        user.name = user.name;
        alias = {
          lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
          lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
          ci = "commit";
          ca = "commit --amend";
          can = "commit --amend --no-edit";
          co = "checkout";
          st = "status --short --branch";
          br = "branch";
          re = "remote";
          sw = "switch";
          swc = "switch --create";
          df = "diff";
          dfs = "diff --staged";
          ad = "add";
          ap = "add --patch";
          unstage = "restore --staged";
          last = "log -1 --stat";
          pf = "push --force-with-lease";
          pl = "pull --ff-only";
          rb = "rebase";
          rbi = "rebase --interactive";
          cp = "cherry-pick";
          sta = "stash push";
          stp = "stash pop";
          gca = "gc --aggressive --prune=now";
        };
        push = {
          autoSetupRemote = true;
        };
        difftool.prompt = false;
      };
    };
    gitui = {
      enable = true;
      keyConfig = ''
        (
          move_left: Some(( code: Char('h'), modifiers: "")),
          move_right: Some(( code: Char('l'), modifiers: "")),
          move_up: Some(( code: Char('k'), modifiers: "")),
          move_down: Some(( code: Char('j'), modifiers: "")),

          stash_open: Some(( code: Char('l'), modifiers: "")),
          open_help: Some(( code: F(1), modifiers: "")),

          status_reset_item: Some(( code: Char('U'), modifiers: "SHIFT")),
        )
      '';
    };
    helix = {
      enable = true;
      defaultEditor = true;
    };
    jjui.enable = true;
    jq.enable = true;
    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = user.name;
          email = user.email;
        };
      };
    };
    mise = {
      enable = true;
      enableFishIntegration = true;
    };
    pandoc.enable = true;
    ripgrep.enable = true;
    starship = {
      enable = true;
      enableFishIntegration = true;
    };
    uv = {
      enable = true;
      settings = {
        # Use uv's own interpreters, never the distro's.
        python-preference = "only-managed";
        python-downloads = "automatic";
      };
      # Latest patch of each supported (not end-of-life) CPython minor, as of
      # 2026-11; see https://devguide.python.org/versions/. Unpinned entries
      # are upgraded on every activation, and anything else managed is pruned.
      python = {
        versions = [ "3.11" "3.12" "3.13" "3.14" "3.15" ];
        default = [ "3.15" ]; # provides `python` and `python3` in ~/.local/bin
        prune = true;
      };
    };
    zellij = {
      enable = true;
      enableFishIntegration = false;
      enableBashIntegration = false;
    };
    zoxide.enable = true;
  };
}
