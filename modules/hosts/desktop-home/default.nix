{ config, ... }:
let
  flakeConfig = config;
  modules = [
    "cli-tools"
    "gui-tools"
    "wofi"
    "wayland-common"
    "waybar"
    "sway"
    "terminals"
  ];
in
{
  flake = {
    nixosConfigurations.desktop-home = flakeConfig.flake.lib.mkSystems.linux "desktop-home";
    modules.nixos."hosts/desktop-home" = {
      imports = (flakeConfig.flake.lib.loadNixosAndHmModuleForUser flakeConfig modules) ++ [
        ./_hardware-configuration.nix
      ];
    };
  };
}
