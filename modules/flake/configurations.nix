{
  lib,
  config,
  inputs,
  ...
}:
let
  username = "chek";

  mkNixos =
    system: cls: name:
    lib.nixosSystem {
      inherit system;
      modules = [
        config.flake.modules.nixos.${cls}
        config.flake.modules.nixos."hosts/${name}"
        {
          home-manager.users.${username}.imports = [
            config.flake.modules.homeManager.homeManager
            (config.flake.modules.homeManager."hosts/${name}" or { })
          ];
          networking.hostName = lib.mkDefault name;
          nixpkgs.hostPlatform = lib.mkDefault system;
          system.stateVersion = "25.05";
        }
      ];
    };

  linux = mkNixos "x86_64-linux" "nixos";
  linux-arm = mkNixos "aarch64-linux" "nixos";
  wsl = mkNixos "x86_64-linux" "wsl";
in
{
  flake.lib = {
    mkSystems = { inherit linux linux-arm wsl; };

    loadNixosAndHmModuleForUser =
      config: modules:
      (builtins.map (module: config.flake.modules.nixos.${module} or { }) modules)
      ++ [
        {
          imports = [ inputs.home-manager.nixosModules.home-manager ];
          home-manager.users.${username}.imports = builtins.map (
            module: config.flake.modules.homeManager.${module} or { }
          ) modules;
        }
      ];
  };
}
