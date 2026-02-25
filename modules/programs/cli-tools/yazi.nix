{
  flake.modules.homeManager.yazi =
    { ... }:
    {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
	shellWrapperName = "y";
      };
    };
}
