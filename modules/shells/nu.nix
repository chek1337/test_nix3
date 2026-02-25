{
  flake.modules.homeManager.nu =
    { ... }:
    {
      programs.nushell = {
        enable = true;
      };
    };
}
