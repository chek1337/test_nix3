{
  flake.modules.homeManager.destop-env =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nautilus ];
    };
}
