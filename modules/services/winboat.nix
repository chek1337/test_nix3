{ ... }:
{
  flake.modules.nixos.winboat =
    {
      config,
      pkgs,
      pkgs-stable,
      ...
    }:
    let
      username = config.settings.username;
    in
    {
      # WinBoat: Run Windows apps on Linux with seamless integration.
      # It uses a containerized Windows VM and FreeRDP RemoteApp.

      # Пин winboat и его замыкания (Electron, FreeRDP) на stable: в unstable
      # Electron 40 помечен EOL и eval падает, поэтому исключение для
      # electron-40.10.5 живёт в config'е pkgs-stable
      # (modules/nixos-params/configurations.nix), а не в nixpkgs.config хоста.
      environment.systemPackages = with pkgs-stable; [
        winboat
        freerdp
      ];

      # WinBoat requires docker or podman to manage its containers.
      virtualisation.docker.enable = true;

      # Ensure user has access to docker and kvm (for virtualization performance).
      users.users.${username}.extraGroups = [
        "docker"
        "kvm"
      ];

      # Prevent the WinBoat container from auto-starting on boot.
      systemd.services.winboat-no-autostart = {
        description = "Disable WinBoat container auto-start";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
        script = ''
          if ${pkgs.docker}/bin/docker inspect WinBoat &>/dev/null; then
            ${pkgs.docker}/bin/docker update --restart=no WinBoat
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    };

  flake.modules.homeManager.winboat = { ... }: { };
}

# dont forget to docker-compose.yaml
# volumes:
#   - ${HOME}:/shared
