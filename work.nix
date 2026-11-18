{ pkgs, ... }:
{
  home.packages = with pkgs; [
    terraform
    jiratui
    github-copilot-cli
    databricks-cli
    hadolint
  ];

  home.sessionVariables = {
    BROWSER = "wslview";
    DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
  };

  programs.awscli.enable = true;

  pi.mcpServers = {
    atlassian.url = "https://mcp.atlassian.com/v1/mcp";
    aws = {
      command = "uvx";
      args = [ "awslabs.core-mcp-server@latest" ];
    };
    datadog = {
      type = "http";
      url = "https://mcp.us3.datadoghq.com/v1/mcp?toolsets=dashboards";
    };
    databricks = {
      type = "http";
      url = "https://dbc-e4009998-54f1.cloud.databricks.com/api/2.0/mcp/functions/system/ai";
    };
    aikido = {
      command = "npx";
      args = [
        "-y"
        "@aikidosec/mcp@latest"
      ];
    };
  };

  programs.pi-coding-agent.settings = {
    defaultProvider = "anthropic";
    defaultModel = "claude-haiku-4-5";
  };

  programs.ssh.settings."tiimely-ml" = {
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
}
