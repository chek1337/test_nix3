{ config, ... }:
let
  flakeConfig = config;
  modules = [ "cli-tools" "firefox" ];
in
{
  flake = {
    nixosConfigurations.desktop-home = flakeConfig.flake.lib.mkSystems.linux "desktop-home";
    modules.nixos."hosts/desktop-home" = {
      imports =
        (flakeConfig.flake.lib.loadNixosAndHmModuleForUser flakeConfig modules)
        ++ [ ./hardware-configuration.nix ];
    };
  };
}
