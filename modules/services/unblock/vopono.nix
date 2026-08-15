{ config, lib, ... }:
let
  nixosMods = config.flake.modules.nixos;
in
{
  flake.modules.nixos.vopono =
    { config, pkgs, ... }:
    {
      imports = [ nixosMods.unblock-wg-secrets ];

      boot.extraModulePackages = lib.mkIf (config.settings.amneziaWgExtraConfigs != [ ]) [
        config.boot.kernelPackages.amneziawg
      ];

      security.sudo.extraRules = [
        {
          users = [ config.settings.username ];
          commands = [
            {
              command = "${pkgs.vopono}/bin/vopono";
              options = [
                "NOPASSWD"
                "SETENV"
              ];
            }
          ];
        }
      ];

      environment.systemPackages =
        with pkgs;
        [
          vopono
          wireguard-tools
        ]
        ++ lib.optional (config.settings.amneziaWgExtraConfigs != [ ]) amneziawg-tools;

      systemd.services.vopono = {
        description = "Vopono root daemon";
        after = [ "network.target" ];
        requires = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        # Демон делает всю привилегированную работу сам (netns, firewall, wg),
        # поэтому инструменты должны быть в PATH юнита: systemd даёт только
        # coreutils/findutils/grep/sed/systemd, и vopono падает с
        # "Neither nftables nor iptables is installed!".
        path =
          with pkgs;
          [
            vopono
            wireguard-tools
            iproute2
            procps
            sudo
          ]
          ++ (if config.networking.nftables.enable then [ nftables ] else [ iptables ])
          ++ lib.optional (config.settings.amneziaWgExtraConfigs != [ ]) amneziawg-tools;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.vopono}/bin/vopono daemon";
          Restart = "on-failure";
          RestartSec = "2s";
          Environment = "RUST_LOG=info";
        };
      };
    };

  flake.modules.homeManager.vopono =
    {
      config,
      pkgs,
      ...
    }:
    let
      wgName = config.settings.wireguardConfigName;
      wgSecret = "/run/secrets/${wgName}";
      vopono = "${pkgs.vopono}/bin/vopono";
      voponoVpnApps = pkgs.writeShellScript "vopono-vpn-apps" ''
        for i in $(seq 1 30); do
          [ -f ${wgSecret} ] && ${pkgs.systemd}/bin/systemctl is-active --quiet vopono.service && break
          sleep 1
        done
        ${vopono} exec --protocol wireguard --custom ${wgSecret} ${pkgs.qutebrowser}/bin/qutebrowser &
        sleep 3
        ${vopono} exec --protocol wireguard --custom ${wgSecret} ${pkgs.ayugram-desktop}/bin/AyuGram &
        wait
      '';
    in
    {
      services.niri.spawnAtStartup = [ "${voponoVpnApps}" ];

      programs.zsh.shellAliases = {
        vopono-up = "sudo systemctl start vopono.service";
        vopono-down = "sudo systemctl stop vopono.service";
        vopono-status = "sudo systemctl status vopono.service";
        vopono-restart = "sudo systemctl restart vopono.service";
        vopono-exec = "vopono exec --custom /run/secrets/${wgName} --protocol wireguard";
      };

      programs.zsh.initContent = ''
        vopono-run() {
          local cfg="$1"; shift
          vopono exec --custom /run/secrets/"$cfg" --protocol wireguard "$@"
        }
        # Запуск AI-агента через VPN с подсказкой для herdr. vopono прячет реальный
        # процесс агента за netns/sudo, поэтому herdr не опознаёт его по имени в
        # foreground-группе панели; HERDR_AGENT=<agent> на foreground-процессе
        # (user-owned vopono-клиент) даёт herdr идентичность напрямую, а состояние
        # он добирает из screen-манифеста. Имя агента = первый аргумент.
        # Хинт намеренно локален для команды — не экспортируем его глобально.
        vopono-agent() {
          local agent="$1"; shift
          HERDR_AGENT="$agent" vopono exec --custom /run/secrets/${wgName} \
            --protocol wireguard "$agent" "$@"
        }
        vopono-file() {
          local cfg="$1"; shift
          vopono exec --custom "$cfg" --protocol wireguard "$@"
        }
        vopono-awg-run() {
          local cfg="$1"; shift
          vopono exec --custom /run/secrets/"$cfg" --protocol amneziawg "$@"
        }
        vopono-awg-file() {
          local cfg="$1"; shift
          vopono exec --custom "$cfg" --protocol amneziawg "$@"
        }
      '';
      # VPN desktop entries replaced by noctalia custom-commands plugin
      # xdg.desktopEntries = {
      #   qutebrowser-vpn = {
      #     name = "qutebrowser (VPN)";
      #     exec = "${pkgs.vopono}/bin/vopono exec --protocol wireguard --custom /run/secrets/${wgName} ${pkgs.qutebrowser}/bin/qutebrowser %U";
      #     icon = "qutebrowser";
      #     comment = "qutebrowser via Vopono WireGuard";
      #     categories = [
      #       "Network"
      #       "WebBrowser"
      #     ];
      #     terminal = false;
      #   };
      #   telegram-desktop-vpn = {
      #     name = "Telegram (VPN)";
      #     exec = "${pkgs.vopono}/bin/vopono exec --protocol wireguard --custom /run/secrets/${wgName} ${pkgs.telegram-desktop}/bin/Telegram -- %u";
      #     icon = "telegram";
      #     comment = "Telegram Desktop via Vopono WireGuard";
      #     categories = [
      #       "Network"
      #       "InstantMessaging"
      #     ];
      #     terminal = false;
      #   };
      # };
    };
}
