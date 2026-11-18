{ lib, config, ... }:
let
  skillType = lib.types.submodule {
    options = {
      name = lib.mkOption { type = lib.types.str; };
      path = lib.mkOption {
        type = lib.types.addCheck lib.types.path lib.pathIsDirectory;
      };
    };
  };
in
{
  options.claude.skills = lib.mkOption {
    type = lib.types.listOf skillType;
    default = [ ];
    description = "List of skills to symlink into ~/.claude/skills";
  };

  config.home.file = lib.listToAttrs (
    map (skill: lib.nameValuePair ".claude/skills/${skill.name}" { source = skill.path; }) config.claude.skills
  );
}
