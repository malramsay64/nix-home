{ pkgs,... }:

{
  home.packages = [
    pkgs.terraform
    pkgs.jiratui
    pkgs.github-copilot-cli
    pkgs.databricks-cli
    pkgs.awscli2
    pkgs.hadolint
  ];

  home.sessionVariables = {
    BROWSER = "wslview";
    DOCKER_HOST="unix:///run/user/1000/podman/podman.sock";
  };

  programs = {
    ssh = import ./hosts.nix;
    awscli.enable = true;
  };
}
