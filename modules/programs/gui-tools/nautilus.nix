{
  flake.modules.homeManager.gui-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nautilus ];
    };
}
