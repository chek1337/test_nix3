{
  flake.modules.homeManager.wofi =
    { pkgs, ... }:
    {
      programs.wofi = {
        enable = true;
        settings = {
          show = "drun";
          width = 600;
          height = 400;
          insensitive = true;
        };
      };
    };
}
