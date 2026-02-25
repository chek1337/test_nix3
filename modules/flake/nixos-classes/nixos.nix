{ inputs, ... }:
{
  flake.modules.nixos.nixos = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.hyprland.nixosModules.default
      inputs.stylix.nixosModules.stylix
    ];
    nix.settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://stylix.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "stylix.cachix.org-1:vbI/rFKtcGOVBmfHeJHovl0XUeOSHwMNFEZNDJqCAHM="
      ];
    };
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
    users.users.chek = {
      isNormalUser = true;
      home = "/home/chek";
      extraGroups = [ "wheel" ];
    };
  };
}
