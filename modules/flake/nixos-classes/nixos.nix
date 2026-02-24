{ inputs, ... }: {
  flake.modules.nixos.nixos = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    users.users.chek = {
      isNormalUser = true;
      home = "/home/chek";
    };
  };
}
