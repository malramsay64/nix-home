{ pkgs, availableSkills, ... }:

{
  claude.skills = [
    availableSkills."vercel-labs"."skills"."find-skills"
  ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    pkgs.helmfile

    pkgs.immich-go
    pkgs.k9s
    pkgs.argocd

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

  programs = {
    ssh.settings."k3s-node-01" = {
      Hostname = "192.168.10.26";
      User = "core";
      identityFile = "~/.ssh/id_ed25519";
    };
    ssh.settings."git.malramsay.com" = {
      Hostname = "git.malramsay.com";
      User = "git";
      identityFile = "~/.ssh/id_ed25519";
    };
    ssh.settings."hamilton" = {
      Hostname = "192.168.10.10";
      User = "ironmal";
      Port = 29979;
      identityFile = "~/.ssh/id_ed25519";
      SetEnv = "TERM=xterm-256color";
    };
  };
}
