{
  flake.modules.homeManager.sublime =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ sublime4 ];
    };
}
