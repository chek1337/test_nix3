{ config, ... }:
let
  flakeConfig = config;
  modules = [ "cli-tools" "gui-tools" "sway" "dektop-env"];
in
{
  flake = {
    nixosConfigurations.desktop-home = flakeConfig.flake.lib.mkSystems.linux "desktop-home";
    modules.nixos."hosts/desktop-home" = {
      imports =
        (flakeConfig.flake.lib.loadNixosAndHmModuleForUser flakeConfig modules)
        ++ [ ./_hardware-configuration.nix ];
    };
  };
}
