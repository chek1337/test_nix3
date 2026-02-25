{ inputs, ... }:
{
  flake.modules.nixos.hyprland =
    { pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
        xwayland.enable = true;
      };

      services.xserver.enable = false;
      security.polkit.enable = true;

      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/Hyprland";
          user = "chek";
        };
      };

      environment.systemPackages = with pkgs; [
        wayland
        grim
        slurp
        wl-clipboard
      ];
    };

  flake.modules.homeManager.hyprland =
    { pkgs, lib, ... }:
    {
      home.sessionVariables = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        GTK_CSD = "0";
      };

      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
        systemd = {
          enable = true;
          extraCommands = lib.mkBefore [
            "systemctl --user stop graphical-session.target"
            "systemctl --user start hyprland-session.target"
          ];
        };

        settings = {
          animations = {
            enabled = true;
            bezier = [
              "md3_decel, 0.05, 0.7, 0.1, 1"
              "workspace, 0.17, 1.17, 0.3, 1"
            ];
            animation = [
              "border, 1, 2, default"
              "fade, 1, 2, md3_decel"
              "windows, 1, 4, md3_decel, popin 60%"
              "workspaces, 1, 5, workspace, slidefadevert 8%"
            ];
          };

          xwayland = {
            force_zero_scaling = true;
          };

          decoration = {
            rounding = 3;
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            fullscreen_opacity = 1.0;
            blur = {
              enabled = true;
              passes = 3;
              size = 16;
            };
          };

          general = {
            gaps_in = 3;
            gaps_out = 7;
            border_size = 3;
            layout = "master";
          };

          input = {
            kb_layout = "us,ru";
            kb_options = "grp:caps_toggle";
            accel_profile = "flat";
            sensitivity = 0.0;
            touchpad = {
              natural_scroll = true;
            };
          };

          misc = {
            disable_autoreload = false;
            disable_hyprland_logo = true;
            focus_on_activate = false;
            force_default_wallpaper = 0;
          };

          bind = [
            "SUPER, Return, exec, kitty"
            "SUPER, D, exec, wofi --show drun"
            "SUPER, Q, killactive"
            "SUPER, F, fullscreen"
            "SUPER SHIFT, Space, togglefloating"
            "SUPER, 1, workspace, 1"
            "SUPER, 2, workspace, 2"
            "SUPER, 3, workspace, 3"
            "SUPER, 4, workspace, 4"
            "SUPER, 5, workspace, 5"
            "SUPER SHIFT, 1, movetoworkspace, 1"
            "SUPER SHIFT, 2, movetoworkspace, 2"
            "SUPER SHIFT, 3, movetoworkspace, 3"
            "SUPER SHIFT, 4, movetoworkspace, 4"
            "SUPER SHIFT, 5, movetoworkspace, 5"
          ];
        };
      };
    };
}
