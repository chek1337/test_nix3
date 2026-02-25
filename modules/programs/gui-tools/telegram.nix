{
  flake.modules.homeManager.telegram =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ telegram-desktop ];
    };
}
