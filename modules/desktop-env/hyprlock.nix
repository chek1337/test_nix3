{ inputs, ... }:
{
  flake.modules.homeManager.hyprlock =
    { pkgs, ... }:
    {
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            hide_cursor = true;
            no_fade_in = false;
          };

          background = {
            monitor = "";
            blur_passes = 3;
            blur_size = 8;
            brightness = 0.6;
          };

          label = {
            monitor = "";
            text = ''cmd[update:1000] echo "$(date +"%H:%M")"'';
            font_size = 64;
            position = "-80, 80";
            halign = "right";
            valign = "bottom";
          };

          input-field = {
            monitor = "";
            size = "300, 50";
            position = "0, 0";
            halign = "center";
            valign = "center";
            fade_on_empty = true;
            fade_timeout = 1000;
            placeholder_text = "";
            hide_input = false;
            rounding = 10;
          };
        };
      };
    };
}
