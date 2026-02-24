{
  flake.modules.homeManager.kitty =
    { ... }:
    {
      programs.kitty = {
        enable = true;
        settings = {
          confirm_os_window_close = 0;
          window_padding_width = 8;
          curstor_trail = 1;
        };
      };
    };
}
