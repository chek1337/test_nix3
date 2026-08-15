{ inputs, ... }:
{
  flake.modules.nixos.nixos =
    { config, ... }:
    let
      username = config.settings.username;
    in
    {
      nix.settings = {
        max-jobs = "auto";
        cores = 0;
        substituters = [
          "https://cache.nixos.org"
          # "https://nix-community.cachix.org"
          # "https://zen-browser.cachix.org"
          # "https://yandex-browser-nix.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          # "zen-browser.cachix.org-1:z/QLGrEkiBYF/7zoHX1Hpuv0B26QrmbVBSy9yDD2tSs="
          # "yandex-browser-nix.cachix.org-1:KTUynR1mK6m4ZVPgM2U5cb/yTa9vBGMU+eRY/l/b7vw="
        ];
        connect-timeout = 3;
        keep-outputs = true;
        keep-derivations = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      nixpkgs.config.allowUnfree = true;
      # NB: nixpkgs.config merges shallowly (`//`), so permittedInsecurePackages
      # must be declared in exactly one module — currently services/winboat.nix.
      users.users.${username} = {
        isNormalUser = true;
        home = "/home/${username}";
        extraGroups = [ "wheel" ];
      };
      time.timeZone = config.settings.timeZone;
      i18n.defaultLocale = "ru_RU.UTF-8";
      programs.nix-ld.enable = true;
    };
}
