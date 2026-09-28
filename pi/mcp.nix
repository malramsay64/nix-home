{ pkgs, profile }:
let
  # Secrets for MCP servers are injected per-server with `op run` (1Password
  # desktop app auth, so first use prompts for approval). Only the op://
  # secret references live in the nix store; the resolved values exist solely
  # in the MCP server's process, never in pi's environment or the agent's
  # bash tool. https://www.1password.dev/get-started/secure-ai-access
  opRun = envFile: command: {
    command = "op";
    args = [ "run" "--env-file=${envFile}" "--" ] ++ command;
  };
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
      homeassistant = opRun
        (pkgs.writeText "homeassistant-mcp.env" ''
          HOMEASSISTANT_TOKEN="op://Homelab/Home Assistant/mcp-token"
        '')
        [ "uvx" "ha-mcp@latest" ]
      // {
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
