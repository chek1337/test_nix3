{ config, ... }:
let
  flakeConfig = config;
  shell = "nu"; 
  modules = [
    "cli-tools"
    "gui-tools"
    "wayland-common"
    "hyprland"
    "terminals"
    "desktop-env"
  ];
in
{
  flake = {
    nixosConfigurations.desktop-home = flakeConfig.flake.lib.mkSystems.linux "desktop-home";
    modules.nixos."hosts/desktop-home" = {
      imports =
        (flakeConfig.flake.lib.loadNixosAndHmModuleForUser flakeConfig modules)
        ++ [ ./_hardware-configuration.nix ]
        ++ [ flakeConfig.flake.modules.nixos.${shell} ];
    };
    modules.homeManager."hosts/desktop-home" = {
      imports = [ flakeConfig.flake.modules.homeManager.${shell} ];
    };
  };
}
