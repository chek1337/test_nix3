{ config, ... }:
{
  flake.modules.homeManager.gui-browsers = {
    imports = with config.flake.modules.homeManager; [
      firefox
      qutebrowser
    ];
  };
}
