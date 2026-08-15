{ lib, ... }:
{
  flake.modules.nixos.settings =
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
          description = ''
            Upstream for the singbox-ru transparent proxy: "vless" parses the
            vless-chumakov secret, "wireguard" parses the WireGuard config named
            by wireguardConfigName. Either way RU traffic stays direct and the
            rest is tunnelled.
          '';
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
          description = ''
            Enable inbound SSH access (openssh daemon, key-only auth, no
            root login). SFTP is bundled with SSH, so file transfer works
            out of the box.
          '';
        };

        remoteSshPort = lib.mkOption {
          type = lib.types.port;
          default = 22;
          description = "TCP port openssh listens on when enableRemoteSsh is true.";
        };

        remoteSshAuthorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Public SSH keys appended to the primary user's authorized_keys
            when enableRemoteSsh is true. Without at least one entry,
            inbound SSH is enabled but no one can log in (key-only auth).
          '';
        };

        enableRemoteDesktop = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Enable Sunshine streaming server for remote GUI access from a
            Moonlight client. Opens the required firewall ports and grants
            the user uinput access for virtual input devices.
          '';
        };

        enableMoonlightClient = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Install the Moonlight client (moonlight-qt) to connect to
            Sunshine streaming servers. Independent of enableRemoteDesktop
            so a host can be only a client, only a server, or both.
          '';
        };

        timeZone = lib.mkOption {
          type = lib.types.str;
          default = "Asia/Novosibirsk";
          description = "System timezone";
        };

        stateVersion = lib.mkOption {
          type = lib.types.str;
          default = "25.11";
          description = "NixOS and home-manager state version";
        };

        colorScheme = lib.mkOption {
          type = lib.types.str;
          default = "nord";
          description = "Base16 scheme name matching a file in pkgs.base16-schemes (e.g. nord, catppuccin-mocha)";
        };

        work = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Mirror of home-manager settings.work.name.";
                };
                email = lib.mkOption {
                  type = lib.types.str;
                  description = "Mirror of home-manager settings.work.email.";
                };
                workDir = lib.mkOption {
                  type = lib.types.str;
                  default = "~/Work/";
                  description = "Mirror of home-manager settings.work.workDir.";
                };
                sshKeyPath = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Mirror of home-manager settings.work.sshKeyPath.";
                };
              };
            }
          );
          default = null;
          description = "Mirror of home-manager settings.work — see home-manager/settings.nix.";
        };
      };
    };
}
