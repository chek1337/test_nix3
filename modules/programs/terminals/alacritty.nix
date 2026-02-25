{
  flake.modules.homeManager.alacritty =
    { ... }:
    {
      programs.alacritty = {
        enable = true;
        settings = {
          window = {
            padding = {
              x = 8;
              y = 8;
            };
          };
        };
      };
    };
}
