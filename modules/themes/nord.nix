{ inputs, ... }:
{
  flake.modules.nixos.nord =
    { pkgs, ... }:
    {
      stylix = {
        enable = true;
        image = inputs.self + "/assets/nord.jpg";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font";
          };
          sansSerif = {
            package = pkgs.inter;
            name = "Inter";
          };
          sizes = {
            terminal = 13;
            applications = 12;
          };
        };
        cursor = {
          package = pkgs.nordzy-cursor-theme;
          name = "Nordzy-cursors";
          size = 24;
        };
      };
    };

  flake.modules.homeManager.nord =
    { ... }:
    {
      stylix.targets.firefox.profileNames = [ "default" ];
    };
}
