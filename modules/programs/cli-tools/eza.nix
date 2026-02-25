{
  flake.modules.homeManager.eza =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ eza ];
      programs.zsh.shellAliases = {
        ls = "eza";
        ll = "eza -l";
        la = "eza -la";
      };
    };
}
