{
  flake.modules.homeManager.eza =
    { pkgs, ... }:
    let
      aliases = {
        l = "eza --grid --color=always --no-filesize --no-time --no-user --no-permissions --icons";
        ls = "eza --color=always --long --git --icons";
        lsa = "eza --color=always --long --git --icons -a";
        tree = "eza --color=always --long --git --icons --tree";
      };
    in
    {
      home.packages = with pkgs; [ eza ];

      programs.zsh.shellAliases = aliases;
      programs.nushell.shellAliases = aliases;
    };
}
