{
  enable = true;
  enableDefaultConfig = false;
  settings = {
    "*".AddKeysToAgent = "yes";

    # Cluster
    "k3s-node-01" = {
      HostName = "192.168.10.26";
      User = "core";
      IdentityFile = "~/.ssh/id_ed25519";
    };

    "k3s-syn-01" = {
      HostName = "192.168.10.27";
      User = "core";
      IdentityFile = "~/.ssh/id_ed25519";
    };

    # Git
    "git.malramsay.com" = {
      HostName = "git.malramsay.com";
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519";
    };

    # Work
    "tiimely-ml" = {
      HostName = "i-005ada91fe3576761";
      User = "ubuntu";
      ForwardAgent = true;
      LocalForward = [
        {
          bind.port = 8888;
          host.address = "localhost";
          host.port = 8888;
        }
      ];
      ProxyCommand = "aws ec2-instance-connect open-tunnel --instance-id i-005ada91fe3576761 --profile tto-corporate";
    };
  };
}
