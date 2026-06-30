{ lib, config, ... }:
let
  cfg = config.claude;

  skillFiles = src:
    let
      entries = builtins.readDir src;
      files = builtins.filter
        (name: entries.${name} == "regular")
        (builtins.attrNames entries);
    in
    builtins.listToAttrs (map (name: {
      name = "claude/skills/${name}";
      value = { source = "${src}/${name}"; };
    }) files);
in
{
  options.claude.skills = lib.mkOption {
    type = lib.types.listOf lib.types.path;
    default = [];
    description = "List of skill directories to symlink into ~/claude/skills";
  };

  config.home.file = builtins.foldl'
    (acc: skill: acc // skillFiles skill)
    {}
    cfg.skills;
}
