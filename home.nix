{
  pkgs,
  config,
  availableSkills,
  ...
}:
let
  home = config.home.homeDirectory;
  trekUrl = "https://trek.malramsay.com/mcp";

  # Secrets for MCP servers are injected per-server with `op run` (1Password
  # desktop app auth, so first use prompts for approval). Only the op://
  # secret references live in the nix store; the resolved values exist solely
  # in the MCP server's process, never in pi's environment or the agent's
  # bash tool. https://www.1password.dev/get-started/secure-ai-access
  opRun = envFile: command: {
    command = "op";
    args = [
      "run"
      "--env-file=${envFile}"
      "--"
    ]
    ++ command;
  };
in
{
  zw.projects = [
    "${home}/Projects/nix-home"
    "${home}/Projects/kubelab"
    "${home}/Projects/jira-ui"
    "${home}/Projects/keyboards"
    "${home}/Projects/rmk"
    "${home}/Projects/personal_site"
    "${home}/Projects/skymap"
    "${home}/Projects/ha-automations"
  ];

  claude.skills = builtins.attrValues availableSkills."awdemos"."opencode-superpowers" ++ [
    {
      name = "gf-df-trip";
      path = ./pi/skills/gf-df-trip;
    }
  ];

  home.packages = with pkgs; [
    helmfile
    rapidraw
    immich-go
    k9s
    argocd
    zola
    wrangler
    llama-cpp-rocm
  ];

  # Delivered by home-manager as a generated personal plugin, so it lives
  # alongside (not inside) the mutable ~/.claude.json.
  programs.claude-code.mcpServers = {
    trek = {
      type = "http";
      url = trekUrl;
    };
    # https://github.com/homeassistant-ai/ha-mcp
    homeassistant =
      opRun
        (pkgs.writeText "homeassistant-claude-mcp.env" ''
          HOMEASSISTANT_TOKEN="op://Homelab/Home Assistant/mcp-token"
        '')
        [
          "uvx"
          "ha-mcp@latest"
        ]
      // {
        env = {
          HOMEASSISTANT_URL = "https://homeassistant.malramsay.com";
          # ha-mcp has no read-only switch for stdio. Tool search hides the
          # full catalogue behind read/write/delete proxy tools, and the
          # write and delete proxies are denied below.
          ENABLE_TOOL_SEARCH = "true";
        };
      };
  };

  # Read-only Home Assistant access: only search and the read proxy are
  # permitted. The plugin prefix is the one home-manager's generated plugin
  # gives trek (mcp__plugin_hm_trek__*).
  programs.claude-code.settings.permissions = {
    allow = [
      "mcp__plugin_hm_homeassistant__ha_search_tools"
      "mcp__plugin_hm_homeassistant__ha_call_read_tool"
    ];
    deny = [
      "mcp__plugin_hm_homeassistant__ha_call_write_tool"
      "mcp__plugin_hm_homeassistant__ha_call_delete_tool"
    ];
  };

  pi.mcpServers = {
    trek.url = trekUrl;
    # https://github.com/homeassistant-ai/ha-mcp
    homeassistant =
      opRun
        (pkgs.writeText "homeassistant-mcp.env" ''
          HOMEASSISTANT_TOKEN="op://Homelab/Home Assistant/mcp-token"
        '')
        [
          "uvx"
          "ha-mcp@latest"
        ]
      // {
        env.HOMEASSISTANT_URL = "https://homeassistant.malramsay.com";
      };
  };
  pi.mcpAdapterOverrides.homeassistant.lifecycle = "lazy-keep-alive";

  programs.pi-coding-agent = {
    # Custom model providers (LiteLLM proxy). The proxy is homelab
    # infrastructure and its key comes from 1Password.
    models = import ./pi/models.nix;
    settings = {
      defaultProvider = "litellm";
      defaultModel = "qwen3.8-27b";
      modelThinkingLevels."litellm/qwen3.8-27b" = "medium";
      # Qwen3.8 only has a 64K window (see pi/models.nix): compact later and
      # keep less verbatim so more of it is left for work between compactions.
      compaction.modelOverrides."litellm/qwen3.8-27b" = {
        reserveTokens = 12288;
        keepRecentTokens = 12000;
      };
    };
  };

  programs.ssh.settings = {
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

    # Home
    "hamilton" = {
      HostName = "192.168.10.10";
      User = "ironmal";
      Port = 29979;
      IdentityFile = "~/.ssh/id_ed25519";
      SetEnv.TERM = "xterm-256color";
    };

    # Git
    "git.malramsay.com" = {
      HostName = "git.malramsay.com";
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519";
    };
  };
}
