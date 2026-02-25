{ config, ... }:
{
  flake.modules.homeManager.terminals = {
    imports = with config.flake.modules.homeManager; [
      kitty
    ];
  };
}
