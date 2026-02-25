{
  flake.modules.homeManager.destkop-env =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nautilus ];
    };
}
