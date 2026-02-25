let
  genericPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        vim
        just
        fzf
        nixfmt
        fastfetch
      ];
    };
in
{
  flake.modules.nixos.cli-tools = {
    imports = [ genericPackages ];
  };
}
