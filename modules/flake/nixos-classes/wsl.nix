{ inputs, ... }: {
  flake.modules.nixos.wsl = {
    imports = [ inputs.nixos-wsl.nixosModules.default ];
    wsl.enable = true;
    wsl.defaultUser = "chek";
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
  };
}
