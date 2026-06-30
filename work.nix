{ pkgs,... }:

{
  home.packages = [
    pkgs.terraform
    pkgs.jiratui
    pkgs.github-copilot-cli
    pkgs.databricks-cli
    pkgs.awscli2
  ];

  home.sessionVariables = {
    COLORTERM = "truecolor";
    BROWSER = "wslview";
    DOCKER_HOST="unix:///run/user/1000/podman/podman.sock";
  };

  programs.ssh.settings."tiimely-ml" = {
    Hostname = "i-005ada91fe3576761";
    User = "ubuntu";
    ForwardAgent = "yes";
    LocalForward = "8888 localhost:8888";
    ProxyCommand = "aws ec2-instance-connect open-tunnel --instance-id i-005ada91fe3576761 --profile tto-corporate";
  };
  programs.awscli.enable = true;

}
