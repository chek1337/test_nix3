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
    { lib, ... }:
    {
      wayland.windowManager.sway = {
        enable = true;
        config = {
          terminal = "kitty";
          modifier = "Mod4";

          input."*" = {
            xkb_layout = "us,ru";
            xkb_options = "grp:alt_shift_toggle";
          };

          keybindings = let
            modifier = "Mod4";
          in lib.mkOptionDefault {
            "${modifier}+Return" = "exec kitty";
            "${modifier}+d" = "exec rofi -show drun";
          };
        };
      };

      programs.kitty = {
        enable = true;
        settings = {
          confirm_os_window_close = 0;
        };
      };
    };
}
