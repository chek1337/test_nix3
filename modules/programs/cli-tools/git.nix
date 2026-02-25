{
  flake.modules.homeManager.git =
    { ... }:
    {
      programs.git = {
        enable = true;
        settings = {
          user.name = "chek1337";
          user.email = "DaniPlay1337@yandex.ru";
          alias.gdsbs = "diff --side-by-side";
          pull.rebase = true;
        };
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          side-by-side = false;
          line-numbers = true;
          navigate = true;
        };
      };
    };
}
