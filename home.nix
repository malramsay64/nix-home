{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "malcolm";
  home.homeDirectory = "/home/malcolm";

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
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello    
    pkgs.iosevka

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
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
  };

  # Let Home Manager install and manage itself.
  programs = {
    home-manager.enable = true;
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
    };
    fd.enable = true;
    fish = {
      enable = true;
      generateCompletions = true;
      
    };
    gh.enable = true;
    git = {
      enable = true;
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
    };
    gitui = {
      enable = true;
      keyConfig = ''
        (
          move_left: Some(( code: Char('h'), modifiers: "")),
          move_right: Some(( code: Char('l'), modifiers: "")),
          move_up: Some(( code: Char('k'), modifiers: "")),
          move_down: Some(( code: Char('j'), modifiers: "")),
        )
      '';
    };
    helix = {
      enable = true;
      defaultEditor = true;
      extraPackages = [
        pkgs.bash-language-server
        pkgs.docker-compose-language-service
        pkgs.dockerfile-language-server-nodejs
        pkgs.terraform-ls
        pkgs.marksman
        pkgs.ruff
        pkgs.tinymist
        pkgs.yaml-language-server
        pkgs.rust-analyzer
        pkgs.typos-lsp
      ];
    };
    jujutsu.enable = true;
    ripgrep.enable = true;
    starship = {
      enable = true;
      enableFishIntegration = true;
    };
    zellij.enable = true;
    zoxide.enable = true;
    
  };
}
