{
  flake.modules.homeManager.firefox =
    { pkgs, ... }:
    {
      programs.firefox = {
        enable = true;
        profiles.default = {
          name = "default";
          settings = {
            "browser.theme.content-theme" = 0;
            "browser.theme.toolbar-theme" = 0;
            "browser.display.background_color" = "#1e1e2e";
          };
        };
      };
    };
}
