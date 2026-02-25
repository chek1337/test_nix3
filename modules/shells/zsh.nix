{
  flake.modules.nixos.zsh =
    { pkgs, ... }:
    {
      programs.zsh.enable = true;
      users.users.chek.shell = pkgs.zsh;
    };

  flake.modules.homeManager.zsh =
    { ... }:
    {
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
      };

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
