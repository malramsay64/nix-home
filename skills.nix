{ lib, config, ... }:
let
  cfg = config.claude;

  skillType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
      };
      path = lib.mkOption {
        type = lib.types.addCheck lib.types.path (p:
          let
            s = toString p;
            entries = builtins.readDir (builtins.dirOf s);
          in
          (entries.${builtins.baseNameOf s} or "regular") == "directory");
      };
    };
  };
in
{
  options.claude.skills = lib.mkOption {
    type = lib.types.listOf skillType;
    default = [];
    description = "List of skills to symlink into ~/.claude/skills";
  };

  config.home.file = builtins.foldl'
    (acc: skill: acc // { ".claude/skills/${skill.name}" = { source = skill.path; }; })
    {}
    cfg.skills;
}
