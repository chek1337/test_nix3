# Shell option: zsh
# Select in hosts/*/default.nix via: shell = "zsh"
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
        oh-my-zsh = {
          enable = true;
          plugins = [ "git" ];
        };
        initContent = ''
                WORDCHARS=""
                bindkey " " magic-space

          source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          source ${pkgs.fzf}/share/fzf/completion.zsh
        '';
      };

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
