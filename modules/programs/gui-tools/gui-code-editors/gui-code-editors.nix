{ config, ... }:
{
  flake.modules.homeManager.gui-code-editors = {
    imports = with config.flake.modules.homeManager; [
      vscode
      sublime
    ];
  };
}
