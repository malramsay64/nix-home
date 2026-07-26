{ pkgs, lib, config, ... }:
let
  cfg = config.programs.pi-coding-agent;
  # configDir is an absolute path (defaults to ~/.pi/agent); home.file needs
  # a path relative to $HOME.
  configDirRelative =
    lib.removePrefix "${config.home.homeDirectory}/" cfg.configDir;
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
      duckdb
      ripgrep

      # Version control used by the agent for commits (see context.md).
      jujutsu
    ];

    settings = {
      theme = "dark";
      defaultProvider = "anthropic";
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
      packages = [
        "git:github.com/obra/superpowers"
        "npm:pi-lsp"
        "npm:pi-mcp-adapter"
      ];

      # Locally managed extensions, e.g. the permission-gate extension below
      # that asks for confirmation before running dangerous bash commands.
      extensions = [
        "extensions/permission-gate.ts"
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
}
