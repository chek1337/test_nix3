{ config, ... }:
let
  flakeConfig = config;
  shell = "zsh"; 
  modules = [ "cli-tools" ];
in
{
  flake = {
    nixosConfigurations.wsl-asuslaptop = flakeConfig.flake.lib.mkSystems.wsl "wsl-asuslaptop";
    modules.nixos."hosts/wsl-asuslaptop" = {
      imports =
        (flakeConfig.flake.lib.loadNixosAndHmModuleForUser flakeConfig modules)
        ++ [ flakeConfig.flake.modules.nixos.${shell} ];
    };
    modules.homeManager."hosts/wsl-asuslaptop" = {
      imports = [ flakeConfig.flake.modules.homeManager.${shell} ];
    };
  };
}
