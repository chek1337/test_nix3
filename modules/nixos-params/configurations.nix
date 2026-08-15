{
  lib,
  config,
  inputs,
  ...
}:
let
  flakeConfig = config;

  clsToHostType = {
    nixos = "desktop";
    wsl = "wsl";
    server = "server";
  };

  shortRev = inputs.self.shortRev or inputs.self.dirtyShortRev or "dirty";
  commitMsgFile = "${inputs.self}/.git-commit-msg";
  rawMsg =
    if builtins.pathExists commitMsgFile then
      lib.removeSuffix "\n" (builtins.readFile commitMsgFile)
    else
      "";
  sanitize =
    str: lib.stringAsChars (c: if builtins.match "[a-zA-Z0-9:_.-]" c != null then c else "-") str;
  commitMsg = sanitize (builtins.substring 0 50 rawMsg);
  nixosLabel = if commitMsg != "" then "${shortRev}.${commitMsg}" else shortRev;

  mkNixos =
    system: cls: name: username:
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        pkgs-stable = import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
          config.permittedInsecurePackages = [
            "openssl-1.1.1w"
            # winboat пинится на stable и тянет Electron 40, который апстрим
            # уже пометил EOL; см. modules/services/winboat.nix.
            "electron-40.10.5"
          ];
        };
      };
      modules = [
        flakeConfig.flake.modules.nixos.settings
        flakeConfig.flake.modules.nixos.${cls}
        flakeConfig.flake.modules.nixos."hosts/${name}"
        (
          { config, ... }:
          {
            settings.username = username;
            settings.hostType = clsToHostType.${cls};
            networking.hostName = lib.mkDefault name;
            nixpkgs.hostPlatform = lib.mkDefault system;
            system.stateVersion = config.settings.stateVersion;
            system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or "dirty";
            system.nixos.label = nixosLabel;
          }
        )
      ];
    };

  mkHome =
    system: cls: name: username:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ inputs.nix-firefox-addons.overlays.default ];
      };
      extraSpecialArgs = {
        pkgs-stable = import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
          config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
        };
      };
      modules = [
        flakeConfig.flake.modules.homeManager.hmSettings
        flakeConfig.flake.modules.homeManager.homeManager
        flakeConfig.flake.modules.homeManager."hosts/${name}"
        {
          home.username = username;
          home.homeDirectory = "/home/${username}";
          settings.username = username;
          settings.hostType = clsToHostType.${cls};
        }
      ];
    };

  linux = username: name: mkNixos "x86_64-linux" "nixos" name username;
  linux-arm = username: name: mkNixos "aarch64-linux" "nixos" name username;
  wsl = username: name: mkNixos "x86_64-linux" "wsl" name username;

  home-linux = username: name: mkHome "x86_64-linux" "nixos" name username;
  home-wsl = username: name: mkHome "x86_64-linux" "wsl" name username;

  iso =
    username: name:
    let
      targetSystem = linux username name;
    in
    lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        flakeConfig.flake.modules.nixos.installer
        {
          networking.hostName = "installer-${name}";
          nixpkgs.hostPlatform = "x86_64-linux";
          system.stateVersion = "25.11";

          isoImage.storeContents = [ targetSystem.config.system.build.toplevel ];
          image.fileName = "nixos-${name}-offline.iso";

          isoImage.contents = [
            {
              source = inputs.self;
              target = "/etc/nixos-config";
            }
          ];
        }
      ];
    };

  nixosMod = name: flakeConfig.flake.modules.nixos.${name} or { };
  hmMod = name: flakeConfig.flake.modules.homeManager.${name} or { };

  loadNixosModules =
    modules: builtins.map (module: flakeConfig.flake.modules.nixos.${module} or { }) modules;

  loadHmModules =
    modules: builtins.map (module: flakeConfig.flake.modules.homeManager.${module} or { }) modules;
in
{
  flake.lib = {
    inherit
      nixosMod
      hmMod
      loadNixosModules
      loadHmModules
      ;

    mkSystems = {
      inherit
        linux
        linux-arm
        wsl
        iso
        ;
    };

    mkHomes = {
      inherit
        home-linux
        home-wsl
        ;
    };
  };
}
