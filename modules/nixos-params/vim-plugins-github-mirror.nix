{
  # Плагины mfussenegger (nvim-dap, nvim-lint) переехали с GitHub на Codeberg,
  # и nixpkgs фетчит их исходники оттуда. Codeberg у провайдера блокируется
  # нестабильно (git fetch виснет на ~130 c и падает по таймауту), готовых
  # путей в cache.nixos.org для них нет — сборка nixvim ложится целиком.
  #
  # GitHub-репозитории остались доступны и не заархивированы, причём нужные
  # nixpkgs ревизии там присутствуют. Подменяем только `url` у fetchgit-src:
  # rev и outputHash берутся из nixpkgs как есть, поэтому пин ревизии не
  # дублируется и хеши пересчитывать не нужно — контент того же коммита
  # идентичен независимо от хоста.
  #
  # NB: зеркала заморожены на момент переезда. Если после `nix flake update`
  # nixpkgs возьмёт более свежий Codeberg-коммит, на GitHub его не окажется и
  # фетч упадёт с «Unable to checkout <rev>» — тогда либо убрать overlay и
  # качать с Codeberg через обход блокировок, либо пинить плагины руками.
  flake.overlays.vimPluginsGithubMirror =
    _final: prev:
    let
      mirror =
        plugin: url:
        plugin.overrideAttrs (old: {
          src = old.src.overrideAttrs (_: {
            inherit url;
          });
        });
    in
    {
      vimPlugins = prev.vimPlugins.extend (
        _pluginsFinal: pluginsPrev: {
          nvim-dap = mirror pluginsPrev.nvim-dap "https://github.com/mfussenegger/nvim-dap";
          nvim-lint = mirror pluginsPrev.nvim-lint "https://github.com/mfussenegger/nvim-lint";
        }
      );
    };
}
