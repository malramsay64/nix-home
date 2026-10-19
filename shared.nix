{
  pkgs,
  pkgs-stable,
  user,
  profile,
  config,
  ...
}:
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = user.username;
  home.homeDirectory = user.home;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.

  home.packages = with pkgs; [
    (writeShellApplication {
      name = "upgrade-everything";
      runtimeInputs = [ nix uv nodejs config.programs.pi-coding-agent.package ];
      text = ''
        flake_dir="''${NIX_HOME_FLAKE:-$HOME/projects/nix-home}"
        if [[ ! -d "$flake_dir" ]]; then
          echo "Nix Home flake directory not found: $flake_dir" >&2
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

        upgrade_uv_tools() {
          uv tool upgrade --all
        }

        upgrade_pi_extensions() {
          pi update --extensions
        }

        refresh_mcp_tool_caches() {
          local entry key
          while IFS= read -r entry; do
            key="''${entry%%:*}"
            if [[ "$key" =~ ^[[:xdigit:]]+$ ]]; then
              case "$entry" in
                *mcp-server-kubernetes*|*@upstash/context7-mcp*|*@aikidosec/mcp*)
                  npm cache npx rm "$key" || return $?
                  ;;
              esac
            fi
          done < <(npm cache npx ls)

          uv cache clean mcp-nixos ha-mcp awslabs.core-mcp-server
        }

        upgrade_determinate_nix() {
          if command -v determinate-nixd >/dev/null 2>&1; then
            /usr/bin/sudo "$(command -v determinate-nixd)" upgrade
          else
            echo "Determinate Nix not detected; skipping the Nix installation upgrade."
          fi
        }

        upgrade_nix_and_home_manager() {
          (cd "$flake_dir" && nix flake update) && \
            home-manager switch --flake "$flake_dir#${profile}"
        }

        ${
          if profile == "work" then
            ''
              upgrade_apt() {
                /usr/bin/sudo apt-get update && /usr/bin/sudo apt-get upgrade -y
              }

              upgrade_winget() {
                winget.exe upgrade --all --accept-source-agreements --accept-package-agreements
              }

              open_windows_update() {
                powershell.exe -NoProfile -Command "Start-Process 'ms-settings:windowsupdate'"
              }

              run_step "Ubuntu system packages (apt)" upgrade_apt
              run_step "Windows packages (winget)" upgrade_winget
              run_step "Open Windows Update settings" open_windows_update
            ''
          else
            ""
        }
        run_step "uv tools" upgrade_uv_tools
        run_step "Pi packages" upgrade_pi_extensions
        run_step "Refresh one-shot MCP tool caches" refresh_mcp_tool_caches
        run_step "Determinate Nix installation" upgrade_determinate_nix
        run_step "Nix flake inputs and Home Manager" upgrade_nix_and_home_manager

        if (( ''${#failures[@]} )); then
          printf '\nUpgrade finished with failures: %s\n' "''${failures[*]}" >&2
          exit 1
        fi
        printf '\nAll upgrades completed successfully.\n'
      '';
    })

    # Core Tools
    iosevka
    uv
    duckdb
    zellij
    typst
    lazyjj
    tree
    just
    bottom
    dust
    hyperfine
    jq
    pqrs
    difftastic
    nixfmt
    mermaid-cli
    prettier
    prettier-plugin-jinja-template
    jjui
    nodejs
    exiftool
    pandoc
    betterleaks

    # Development
    opencode
  ];
  fonts.fontconfig.enable = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    ".config/alacritty/alacritty.toml".source = config/alacritty/alacritty.toml;
    ".config/alacritty/one_dark.toml".source = config/alacritty/one_dark.toml;
    ".config/helix/config.toml".source = config/helix/config.toml;
    ".config/helix/languages.toml".source = config/helix/languages.toml;
    ".config/zellij/config.kdl".source = config/zellij/config.kdl;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/malcolm/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    COLORTERM = "truecolor";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # Let Home Manager install and manage itself.
  services.ssh-agent.enable = true;

  programs = {
    # Profile-specific MCP servers are added via programs.claude-code.mcpServers
    # (e.g. in home.nix).
    claude-code.enable = true;

    home-manager.enable = true;
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
    };
    bat.enable = true;
    direnv = {
      enable = true;
      config = {
        global = {
          skip_dotenv = false;
        };
      };
    };
    fd.enable = true;
    fish = {
      enable = true;
      generateCompletions = true;
      interactiveShellInit = ''
        COMPLETE=fish jj | source
        set -gx GITHUB_PERSONAL_ACCESS_TOKEN (gh auth token 2>/dev/null)
      '';
    };
    gh.enable = true;
    delta = {
      enable = true;
      enableGitIntegration = true;
    };
    git = {
      enable = true;
      signing.format = null;
      settings = {
        user.email = user.email;
        user.name = user.name;
        delta.enable = true;
        aliases = {
          lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
          lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
          ci = "commit";
          co = "checkout";
          st = "status";
          br = "branch";
          re = "remote";
          sw = "switch";
          gca = "gc --aggressive --prune=now";
        };
        push = {
          autoSetupRemote = true;
        };
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
      extraPackages = [
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
        pkgs.ruff
        pkgs.prettierd
        pkgs.omnisharp-roslyn
        pkgs.ty
        pkgs.zizmor
      ];
    };
    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = user.name;
          email = user.email;
        };
      };
    };
    ripgrep.enable = true;
    starship = {
      enable = true;
      enableFishIntegration = true;
    };
    uv.enable = true;
    zellij = {
      enable = true;
      enableFishIntegration = false;
      enableBashIntegration = false;
    };
    zoxide.enable = true;
  };
}
