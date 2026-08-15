{ lib, ... }:
{
  flake.modules.homeManager.hmSettings =
    { lib, config, ... }:
    {
      options.settings = {
        username = lib.mkOption {
          type = lib.types.str;
          description = "Primary user's username";
        };

        hostType = lib.mkOption {
          type = lib.types.enum [
            "desktop"
            "wsl"
            "server"
          ];
          description = "Type of this host";
        };

        isDesktop = lib.mkOption {
          type = lib.types.bool;
          default = config.settings.hostType == "desktop";
          readOnly = true;
          description = "Whether this is a desktop host";
        };

        isWSL = lib.mkOption {
          type = lib.types.bool;
          default = config.settings.hostType == "wsl";
          readOnly = true;
          description = "Whether this is a WSL host";
        };

        isServer = lib.mkOption {
          type = lib.types.bool;
          default = config.settings.hostType == "server";
          readOnly = true;
          description = "Whether this is a server host";
        };

        isLaptop = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this is a laptop (portable) host";
        };

        isWorkstation = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Whether this host is a development workstation.
            Aggregators use this to exclude home-only software (kdenlive, obs,
            image-editors, discord, qbittorrent, gaming, waydroid).
          '';
        };

        hasBluetooth = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this host has bluetooth";
        };

        enableRemoteSsh = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Mirror of nixos settings.enableRemoteSsh — see nixos-classes/settings.nix.";
        };

        remoteSshPort = lib.mkOption {
          type = lib.types.port;
          default = 22;
          description = "Mirror of nixos settings.remoteSshPort.";
        };

        remoteSshAuthorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Mirror of nixos settings.remoteSshAuthorizedKeys.";
        };

        enableRemoteDesktop = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Mirror of nixos settings.enableRemoteDesktop — see nixos-classes/settings.nix.";
        };

        enableMoonlightClient = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Mirror of nixos settings.enableMoonlightClient — see nixos-classes/settings.nix.";
        };

        wireguardConfigName = lib.mkOption {
          type = lib.types.str;
          default = "wireguard-desktop-home";
          description = "Name of the sops-encrypted wireguard config file (without .conf)";
        };

        wireguardExtraConfigs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional sops-encrypted wireguard config names to expose in /run/secrets/";
        };

        amneziaWgExtraConfigs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Sops-encrypted AmneziaWG config names to expose in /run/secrets/ for vopono --protocol amneziawg";
        };

        singboxRuUpstream = lib.mkOption {
          type = lib.types.enum [
            "vless"
            "wireguard"
          ];
          default = "wireguard";
          description = "Mirror of nixos settings.singboxRuUpstream — see nixos-classes/settings.nix.";
        };

        kanataKeyboardDevices = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Keyboard device paths kanata should grab on this host
            (e.g. /dev/input/by-path/platform-i8042-serio-0-event-kbd for a
            built-in laptop keyboard). Empty list = let kanata auto-detect
            and intercept all keyboards. Find paths with: ls /dev/input/by-path/
          '';
        };

        colorScheme = lib.mkOption {
          type = lib.types.str;
          default = "nord";
          description = "Base16 scheme name matching a file in pkgs.base16-schemes (e.g. nord, catppuccin-mocha)";
        };

        enableRice = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to spawn rice terminals on startup (nitch, lavat, nvim rice session)";
        };

        work = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Git user.name for repositories under workDir.";
                };
                email = lib.mkOption {
                  type = lib.types.str;
                  description = "Git user.email for repositories under workDir.";
                };
                workDir = lib.mkOption {
                  type = lib.types.str;
                  default = "~/Work/";
                  description = ''
                    Directory prefix (trailing slash required) under which
                    work repos live. Matched by git includeIf gitdir.
                  '';
                };
                sshKeyPath = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = ''
                    Path to private SSH key used for git over SSH in workDir.
                    null = fall back to ssh-agent default identity.
                  '';
                };
              };
            }
          );
          default = null;
          description = ''
            Per-host work identity for git/ssh. null = no work setup on this
            host; non-null applies the identity to repos under workDir via
            git includeIf.
          '';
        };
      };
    };
}
