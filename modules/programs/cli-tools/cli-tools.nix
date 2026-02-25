{ config, ... }:
{
  flake.modules.homeManager.cli-tools = {
    imports = with config.flake.modules.homeManager; [
      eza
      yazi
    ];
  };
}
