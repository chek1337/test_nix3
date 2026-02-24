{ config, ... }:
let
  flakeConfig = config;
  modules = [ "cli-tools" ];
in
{
  flake = {
    nixosConfigurations.wsl-asuslaptop = flakeConfig.flake.lib.mkSystems.wsl "wsl-asuslaptop";
    modules.nixos."hosts/wsl-asuslaptop" = {
      imports = flakeConfig.flake.lib.loadNixosAndHmModuleForUser flakeConfig modules;
    };
  };
}
