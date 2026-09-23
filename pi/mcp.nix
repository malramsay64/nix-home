{ profile }:
let
  mcpServersCommon = {
    github = {
      url = "https://api.githubcopilot.com/mcp/";
      auth = "oauth";
    };
    kubernetes = {
      command = "npx";
      args = [ "-y" "mcp-server-kubernetes" ];
      lifecycle = "lazy";
    };
    nixos = {
        command= "uvx";
        args= ["mcp-nixos"];
        lifecycle= "lazy";
      };
    context7 = {
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
      lifecycle = "lazy";
    };
  };

  mcpServersByProfile = {
    home = {
      trek = {
        url = "https://trek.malramsay.com/mcp";
        auth = "oauth";
      };
      # https://github.com/homeassistant-ai/ha-mcp
      # HOMEASSISTANT_TOKEN is exported by the pi wrapper (see pi.nix) so it
      # isn't baked into the nix store; ha-mcp inherits it via inheritEnv.
      homeassistant = {
        command = "uvx";
        args = [ "ha-mcp@latest" ];
        env = {
          HOMEASSISTANT_URL = "https://homeassistant.malramsay.com";
        };
        lifecycle = "lazy";
      };
    };
    work = {
      atlassian = {
        url = "https://mcp.atlassian.com/v1/mcp";
        auth = "oauth";
      };
      aws = {
        command = "uvx";
        args = [ "awslabs.core-mcp-server@latest" ];
        lifecycle = "lazy";
      };
      datadog = {
        type = "http";
        url = "https://mcp.us3.datadoghq.com/v1/mcp?toolsets=dashboards";
      };
      databricks = {
        type = "http";
        url = "https://dbc-e4009998-54f1.cloud.databricks.com/api/2.0/mcp/functions/system/ai";
        auth = "oauth";
      };
      aikido = {
        command = "npx";
        args = [ "-y" "@aikidosec/mcp@latest" ];
        lifecycle = "lazy";
      };
    };
  };

in
{
  mcpServers = mcpServersCommon // (mcpServersByProfile.${profile} or { });
}
