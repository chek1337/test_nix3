{ config, ... }:
{
  flake.modules.homeManager.gui-tools = {
    imports = with config.flake.modules.homeManager; [
      gui-browsers
      gui-code-editors
      telegram
      nautilus
    ];
  };
}
