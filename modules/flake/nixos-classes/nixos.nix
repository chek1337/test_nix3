{ inputs, ... }:
{
  flake.modules.nixos.nixos = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixpkgs.config.allowUnfree = true;
    users.users.chek = {
      isNormalUser = true;
      home = "/home/chek";
      extraGroups = [ "wheel" ];
    };
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];
  };
}
