{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.alacritty;
  tomlFormat = pkgs.formats.toml { };
in
{
  options = {
    programs.alacritty = {
      enable = mkEnableOption "Alacritty";

      package = mkOption {
        type = types.package;
        default = pkgs.alacritty;
        defaultText = literalExpression "pkgs.alacritty";
        description = "The Alacritty package to install.";
      };

      settings = mkOption {
        type = tomlFormat.type;
        default = { };
        example = literalExpression ''
          {
            window.dimensions = {
              lines = 3;
              columns = 200;
            };
            key_bindings = [
              {
                key = "K";
                mods = "Control";
                chars = "\\x0c";
              }
            ];
          }
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/alacritty/alacritty.yml</filename>. See
          <link xlink:href="https://github.com/alacritty/alacritty/blob/master/alacritty.yml"/>
          for the default configuration.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];

      xdg.configFile."alacritty/alacritty.toml" = mkIf (cfg.settings != { }) {
        # TODO: Replace by the generate function but need to figure out how to
        # handle the escaping first.
        #
        # source = yamlFormat.generate "alacritty.yml" cfg.settings;

        source = pkgs.runCommand "alacritty-unescaped.toml" { } ''
          sed -E 's/\\\\/\\/g' ${tomlFormat.generate "alacritty.toml" cfg.settings} > "$out"
        '';
      };
    })
  ];
}
