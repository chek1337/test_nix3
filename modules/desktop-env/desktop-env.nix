{ config, ... }:
{
  flake.modules.homeManager.desktop-env = {
    imports = with config.flake.modules.homeManager; [
      waybar
      wofi
      hyprlock
    ];
  };
}
