{
  # tmux-интеграция herdr: prefix + a открывает herdr во floating-окне tmux.
  #
  # Один herdr на все сессии: herdr — клиент-серверный (см. `herdr --help`),
  # голый `herdr` поднимает или подключается к persistent-сессии. Поэтому popup
  # не создаёт ничего своего: он просто attach'ится к тому же серверу из любой
  # tmux-сессии, а закрытие popup'а (или detach герром на prefix+shift+D) гасит
  # лишь клиента — агенты продолжают крутиться в фоне.
  #
  # Префиксы не конфликтуют: tmux — C-Space (core.nix), herdr — C-b
  # (modules/programs/cli-tools/herdr.nix). Русского дубля на `ф` намеренно нет.
  #
  # Подмодуль входит в hmMods.tmux, а значит и в портативный packages/tmux.nix:
  # ссылка на ${pkgs.herdr} по store-пути тянет туда сам herdr (+62 МиБ), так что
  # prefix+a работает и на чужой машине. Конфиг herdr (кеймап/тема) там не
  # прокидывается — он кладётся HM-активацией из modules/programs/cli-tools/herdr.nix,
  # так что портативный herdr стартует со своими дефолтами (prefix C-b совпадает).
  flake.modules.homeManager.tmux-herdr =
    { pkgs, config, ... }:
    let
      c = config.lib.stylix.colors.withHashtag;

      # Открыть herdr popup'ом. Отдельным скриптом, а не инлайн-биндом, из-за
      # floax: внутри floax-popup'а (сессия <base>_<origin>, см. sesh.nix)
      # нельзя показать второй popup поверх первого — он налезает на него. Тогда
      # повторяем приём tmux-sesh: закрыть floax, пометить origin-сессию в
      # FLOAX_OPEN_SESSIONS (чтобы `tmux-last` потом восстановил floax) и открыть
      # herdr уже на origin-клиенте.
      tmuxHerdr = pkgs.writeShellScriptBin "tmux-herdr" ''
        current=$(tmux display-message -p '#S')
        self_client=$(tmux display-message -p '#{client_name}')

        base=$(tmux show-option -gqv @floax-session-name)
        base=''${base:-scratch}

        popup() {
          # $@ — дополнительные флаги display-popup (клиент / стартовый каталог).
          tmux display-popup "$@" -E -w 90% -h 90% \
            -T ' Herdr ' -b rounded \
            -S 'fg=${c.base0D}' -s 'fg=${c.base05}' \
            '${pkgs.herdr}/bin/herdr'
        }

        case "$current" in
          "''${base}_"*)
            origin=$(tmux showenv -g ORIGIN_SESSION 2>/dev/null \
              | sed -n 's/^ORIGIN_SESSION=//p')
            [ -n "$origin" ] || origin=''${current#''${base}_}
            origin_client=$(tmux list-clients -t "$origin" \
              -F '#{client_name}' 2>/dev/null | head -1)
            [ -n "$origin_client" ] || origin_client=$self_client

            # Пометить origin для авто-восстановления popup'а при возврате.
            l=$(tmux showenv -g FLOAX_OPEN_SESSIONS 2>/dev/null \
              | sed -n 's/^FLOAX_OPEN_SESSIONS=//p')
            case " $l " in
              *" $origin "*) ;;
              *) tmux setenv -g FLOAX_OPEN_SESSIONS "''${l:+$l }$origin" ;;
            esac

            tmux detach-client
            popup -c "$origin_client"
            ;;
          *)
            # -d нужен лишь при самом первом запуске (сервер herdr наследует
            # каталог); последующие attach'и берут состояние с сервера.
            popup -d '#{pane_current_path}'
            ;;
        esac
      '';
    in
    {
      home.packages = [ tmuxHerdr ];

      programs.tmux.extraConfig = ''
        # Глобальный herdr во floating-окне
        bind a run-shell "${tmuxHerdr}/bin/tmux-herdr"
      '';
    };
}
