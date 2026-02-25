{ config, ... }: {
  flake.modules.homeManager.shells = {
    imports = with config.flake.modules.homeManager; [
      zsh
      nu
    ];
  };

  flake.modules.nixos.shells = {
    imports = [ config.flake.modules.nixos.zsh ];
  };
}
