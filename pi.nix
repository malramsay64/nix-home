{ pkgs, lib, config, profile, ... }:
let
  cfg = config.programs.pi-coding-agent;
  # configDir is an absolute path (defaults to ~/.pi/agent); home.file needs
  # a path relative to $HOME.
  configDirRelative =
    lib.removePrefix "${config.home.homeDirectory}/" cfg.configDir;

  jsonFormat = pkgs.formats.json { };

  mcpConfig = import ./pi/mcp.nix { inherit pkgs profile; };
  modelsConfig = import ./pi/models.nix { inherit config; };

  # pi-lsp server config, written to <configDir>/lsp.json (global config,
  # trusted automatically). Python is wired to `ruff server` (lint/format
  # diagnostics) and `ty server` (Astral's type checker, also LSP-capable) --
  # both ship with their own language server, so pi-lsp can drive them
  # directly instead of going through pyright/mypy. Both are launched via
  # `uv run` so pi-lsp resolves each project's own pinned ruff/ty version
  # (as declared in its pyproject.toml/uv.lock) rather than a global one;
  # `uv` itself comes from extraPackages below.
  lspConfig = {
    version = 1;
    servers = [
      {
        id = "ruff";
        enabled = true;
        include = [ "**/*.py" "**/*.pyi" ];
        rootMarkers = [ "pyproject.toml" "uv.lock" "setup.py" "requirements.txt" ];
        bin = "uv";
        args = [ "run" "ruff" "server" ];
        cwd = "{root}";
        languageIdByExtension = { ".py" = "python"; ".pyi" = "python"; };
        startupTimeoutMs = 45000;
        diagnosticsWaitMs = 1500;
        initializationOptions = { };
        settings = { };
      }
      {
        id = "ty";
        enabled = true;
        include = [ "**/*.py" "**/*.pyi" ];
        rootMarkers = [ "pyproject.toml" "uv.lock" ];
        bin = "uv";
        args = [ "run" "ty" "server" ];
        cwd = "{root}";
        languageIdByExtension = { ".py" = "python"; ".pyi" = "python"; };
        startupTimeoutMs = 45000;
        diagnosticsWaitMs = 2000;
        initializationOptions = { };
        settings = { };
      }
    ];
  };
in
{
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

    settings = {
      theme = "dark";
      defaultProvider = "github-copilot";
      defaultModel = "gpt-5.6-luna";
      compaction = {
        enabled = true;
      };
      retry = {
        enabled = true;
        maxRetries = 3;
      };

      # Superpowers: a structured development methodology (brainstorming ->
      # planning -> TDD -> review) shipped as a pi package.
      # https://github.com/obra/superpowers
      #
      # pi-lsp: LSP diagnostics and language-server navigation tools
      # (go-to-definition, references, hover, rename, etc.) exposed to the
      # agent as tools. https://www.npmjs.com/package/pi-lsp
      #
      # pi-mcp-adapter: lets pi connect to Model Context Protocol (MCP)
      # servers as an extension. https://www.npmjs.com/package/pi-mcp-adapter
      #
      # pi-subagents: dispatch subagents (single-agent, chain, parallel,
      # async, forked-context, resume/status workflows) via a `subagent`
      # tool. https://www.npmjs.com/package/pi-subagents
      #
      # pi-lens: real-time code feedback (LSP, linters, formatters,
      # type-checking, structural analysis via ast-grep/jscpd/knip/etc.).
      # https://www.npmjs.com/package/pi-lens
      packages = [
        # "git:github.com/obra/superpowers"
        "npm:pi-lsp"
        "npm:pi-mcp-adapter"
        "npm:pi-subagents"
        "npm:pi-web-access"
        # "npm:pi-lens"
      ];

      # Locally managed extensions, e.g. the permission-gate extension below
      # that asks for confirmation before running dangerous bash commands.
      extensions = [
        "extensions/permission-gate.ts"
        "extensions/intelligent-find.ts"
      ];
    };

    # Global instructions written to ~/.pi/agent/AGENTS.md, e.g. telling the
    # agent to use `jj` rather than `git` for version control.
    context = ./pi/context.md;
  };

  # Extensions referenced by programs.pi-coding-agent.settings.extensions
  # above, resolved relative to programs.pi-coding-agent.configDir.
  home.file."${configDirRelative}/extensions/permission-gate.ts".source =
    ./pi/extensions/permission-gate.ts;
  home.file."${configDirRelative}/extensions/intelligent-find.ts".source =
    ./pi/extensions/intelligent-find.ts;

  # MCP server config consumed by pi-mcp-adapter.
  home.file."${configDirRelative}/mcp.json".source =
    jsonFormat.generate "pi-mcp-adapter-mcp.json" mcpConfig;

  # pi-lsp global server config (see lspConfig above).
  home.file."${configDirRelative}/lsp.json".source =
    jsonFormat.generate "pi-lsp-lsp.json" lspConfig;

  # User-level skills, discovered from <configDir>/skills/.
  home.file."${configDirRelative}/skills/gf-df-trip".source =
    ./pi/skills/gf-df-trip;

  # Custom model providers (LiteLLM proxy) consumed by pi directly. Home only:
  # the proxy is homelab infrastructure and its key comes from 1Password.
  home.file."${configDirRelative}/models.json" = lib.mkIf (profile == "home") {
    source = jsonFormat.generate "pi-models.json" modelsConfig;
  };
}
