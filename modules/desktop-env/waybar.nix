{
  flake.modules.homeManager.waybar =
    { pkgs, ... }:
    {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        systemd.target = "graphical-session.target";

        settings = [
          {
            layer = "top";
            position = "top";
            exclusive = true;
            fixed-center = true;
            gtk-layer-shell = true;
            margin-top = 7;
            margin-left = 7;
            margin-right = 7;

            modules-left = [
              "sway/workspaces"
            ];

            modules-center = [
              "clock"
            ];

            modules-right = [
              "sway/language"
              "tray"
              "pulseaudio"
              "cpu"
              "memory"
              "network"
              "battery"
            ];

            "sway/workspaces" = {
              all-outputs = true;
              disable-scroll = true;
            };

            "sway/language" = {
              format = "{}";
              format-en = "US";
              format-ru = "RU";
            };

            clock = {
              format = "{:%a %b %d, %H:%M}";
            };

            tray = {
              icon-size = 15;
              spacing = 8;
            };

            pulseaudio = {
              format = "{volume}% {icon}";
              format-muted = "󰖁";
              format-icons.default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
              on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
              tooltip = false;
            };

            battery = {
              format = "{icon} {capacity}%";
              format-charging = " {capacity}%";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
              interval = 5;
              states = {
                warning = 30;
                critical = 15;
              };
            };

            cpu = {
              interval = 5;
              format = " {usage}%";
              tooltip = false;
              states = {
                warning = 70;
                critical = 90;
              };
            };

            memory = {
              interval = 5;
              format = " {percentage}%";
              tooltip = " {used:0.1f}G/{total:0.1f}G";
              states = {
                warning = 70;
                critical = 90;
              };
            };

            network = {
              format-wifi = "󰤨 {essid}";
              format-ethernet = "󰈀";
              format-disconnected = "⚠ Disconnected";
              tooltip-format-wifi = "{essid} ({signalStrength}%)";
              interval = 5;
            };
          }
        ];
      };
    };
}
