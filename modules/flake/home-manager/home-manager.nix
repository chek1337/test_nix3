{
  flake.modules.homeManager.homeManager =
    { ... }:
    {
      home.stateVersion = "25.05";
      nixpkgs.config.allowUnfree = true;
    };
}
