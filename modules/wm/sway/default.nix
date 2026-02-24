{
  flake.modules.nixos.sway =
    { pkgs, ... }:
    {
      programs.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
      };

      services.xserver.enable = false;
      security.polkit.enable = true;

      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${pkgs.sway}/bin/sway";
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

  flake.modules.homeManager.sway =
    { pkgs, lib, ... }:
    {
      home.sessionVariables = {
        XDG_CURRENT_DESKTOP = "sway";
        XDG_SESSION_DESKTOP = "sway";
      };

      wayland.windowManager.sway = {
        enable = true;
        config = {
          terminal = "kitty";
          modifier = "Mod4";

          gaps.inner = 7;
          bars = [];
          window.titlebar = false;

          input = {
            "type:keyboard" = {
              xkb_layout = "us,ru";
              xkb_options = "grp:alt_shift_toggle";
              repeat_delay = "300";
              repeat_rate = "60";
            };
            "type:touchpad" = {
              natural_scroll = "enabled";
              tap = "enabled";
            };
          };

          keybindings = let
            modifier = "Mod4";
          in lib.mkOptionDefault {
            "${modifier}+Return" = "exec kitty";
            "${modifier}+d" = "exec wofi --show drun";
          };
        };
      };
    };
}
