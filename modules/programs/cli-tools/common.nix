let
  genericPackages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        vim
      ];
    };
in
{
  flake.modules.nixos.cli-tools = {
    imports = [ genericPackages ];
  };
}
