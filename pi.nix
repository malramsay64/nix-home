{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.pi-coding-agent;
  jsonFormat = pkgs.formats.json { };

  # pi-lsp server config, written to <configDir>/lsp.json (global config,
  # trusted automatically). Python is wired to `ruff server` (lint/format
  # diagnostics) and `ty server` (Astral's type checker). Both are launched via
  # `uv run` so pi-lsp resolves each project's own pinned ruff/ty version
  # (as declared in its pyproject.toml/uv.lock) rather than a global one;
  # `uv` itself comes from extraPackages below.
  mkUvPythonLsp =
    {
      id,
      rootMarkers,
      diagnosticsWaitMs,
    }:
    {
      inherit id rootMarkers diagnosticsWaitMs;
      enabled = true;
      include = [
        "**/*.py"
        "**/*.pyi"
      ];
      bin = "uv";
      args = [
        "run"
        id
        "server"
      ];
      cwd = "{root}";
      languageIdByExtension = {
        ".py" = "python";
        ".pyi" = "python";
      };
      startupTimeoutMs = 45000;
      initializationOptions = { };
      settings = { };
    };

  lspConfig = {
    version = 1;
    servers = [
      (mkUvPythonLsp {
        id = "ruff";
        rootMarkers = [
          "pyproject.toml"
          "uv.lock"
          "setup.py"
          "requirements.txt"
        ];
        diagnosticsWaitMs = 1500;
      })
      (mkUvPythonLsp {
        id = "ty";
        rootMarkers = [
          "pyproject.toml"
          "uv.lock"
        ];
        diagnosticsWaitMs = 2000;
      })
    ];
  };

  mcpServerType = lib.types.attrsOf jsonFormat.type;
in
{
  options.pi = {
    mcpServers = lib.mkOption {
      type = mcpServerType;
      default = { };
      description = ''
        MCP servers written to <configDir>/mcp.json, read by both Pi and
        pi-mcp-adapter. Keep entries to fields in Pi's mcp.json schema.
      '';
    };
    mcpAdapterOverrides = lib.mkOption {
      type = mcpServerType;
      default = { };
      description = ''
        pi-mcp-adapter-only per-server fields (e.g. lifecycle), written to
        <configDir>/mcp-adapter.json so they stay out of Pi's mcp.json.
      '';
    };
  };

  config = {
    # Servers shared by every profile; profiles add their own in home.nix/work.nix.
    pi.mcpServers = {
      github.url = "https://api.githubcopilot.com/mcp/";
      kubernetes = {
        command = "npx";
        args = [
          "-y"
          "mcp-server-kubernetes"
        ];
      };
      nixos = {
        command = "uvx";
        args = [ "mcp-nixos" ];
      };
      context7 = {
        command = "npx";
        args = [
          "-y"
          "@upstash/context7-mcp"
        ];
      };
    };

    programs.pi-coding-agent = {
      enable = true;

      # Tools available on PATH to the pi agent itself (bash tool, packages it
      # installs via `pi packages add`, MCP adapters, etc). Chosen to cover
      # infrastructure, data science, and backend API workflows.
      extraPackages = with pkgs; [
        # JS/TS runtime needed for npm: packages pi can install (e.g. MCP
        # adapters, termdraw) and for backend API dev/debugging.
        nodejs
        bun

        # Infrastructure / ops
        kubectl
        kubernetes-helm
        terraform
        awscli2
        jq
        yq-go
        httpie

        # Data science / data engineering
        uv
        # ruff/ty on PATH as a fallback for ad-hoc `bash` use outside a
        # uv-managed project; the pi-lsp servers above run each project's own
        # pinned versions via `uv run` instead of these.
        ruff
        ty
        duckdb
        ripgrep
        fd

        # Version control used by the agent for commits (see context.md).
        jujutsu
      ];

      # Profile-specific provider/model defaults live in home.nix and work.nix.
      settings = {
        theme = "dark";
        compaction.enabled = true;
        retry = {
          enabled = true;
          maxRetries = 3;
        };

        # pi-subagents uses fresh context by default, while its builtin agents
        # still inherit repository instructions. Keep that behavior explicit so
        # children don't accidentally rely on unrelated parent conversation.
        subagents.defaultSubagentContext = "fresh";

        # pi-lsp: LSP diagnostics and navigation tools exposed to the agent.
        #   https://www.npmjs.com/package/pi-lsp
        # pi-mcp-adapter: connect pi to MCP servers.
        #   https://www.npmjs.com/package/pi-mcp-adapter
        # pi-subagents: dispatch subagents via a `subagent` tool.
        #   https://www.npmjs.com/package/pi-subagents
        # Disabled: superpowers (git:github.com/obra/superpowers), pi-lens.
        packages = [
          "npm:pi-lsp"
          "npm:pi-mcp-adapter"
          # Pin the extension so declarative installs are reproducible.
          "npm:pi-subagents@0.81.0"
          "npm:pi-web-access"
        ];

        # Locally managed extensions (installed below). pi-mcp-adapter supplies
        # its own /mcp command, so disable Pi's built-in MCP extension to avoid
        # loading two extensions that register /mcp.
        extensions = [
          "-builtin:mcp"
          "extensions/permission-gate.ts"
          "extensions/intelligent-find.ts"
        ];
      };

      # Global instructions written to <configDir>/AGENTS.md.
      context = ./pi/context.md;
    };

    home.file = lib.mapAttrs' (name: value: lib.nameValuePair "${cfg.configDir}/${name}" value) (
      {
        "extensions/permission-gate.ts".source = ./pi/extensions/permission-gate.ts;
        "extensions/intelligent-find.ts".source = ./pi/extensions/intelligent-find.ts;
        "mcp.json".source = jsonFormat.generate "pi-mcp.json" { mcpServers = config.pi.mcpServers; };
        "lsp.json".source = jsonFormat.generate "pi-lsp.json" lspConfig;
        # User-level skills, discovered from <configDir>/skills/.
        "skills/gf-df-trip".source = ./pi/skills/gf-df-trip;
      }
      // lib.optionalAttrs (config.pi.mcpAdapterOverrides != { }) {
        "mcp-adapter.json".source = jsonFormat.generate "pi-mcp-adapter.json" {
          mcpServers = config.pi.mcpAdapterOverrides;
        };
      }
    );
  };
}
