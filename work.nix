{ pkgs,... }:

{
  home.packages = [
    pkgs.terraform
  ];

  programs.ssh.settings."tiimely-ml" = {
    Hostname = "i-005ada91fe3576761";
    User = "ubuntu";
    ForwardAgent = "yes";
    LocalForward = "8888 localhost:8888";
    ProxyCommand = "aws ec2-instance-connect open-tunnel --instance-id i-005ada91fe3576761 --profile tto-corporate";
  };
  home.sessionVariables = {
    COLORTERM = "truecolor";
    BROWSER = "wslview";
    DOCKER_HOST="unix:///run/user/1000/podman/podman.sock";
  };

}
