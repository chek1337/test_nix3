{ inputs, ... }:
{
  flake.modules.homeManager.noctalia =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      isLaptop = config.settings.isLaptop;
      hasBluetooth = config.settings.hasBluetooth;
      wgName = config.settings.wireguardConfigName;
      voponoExec = "${pkgs.vopono}/bin/vopono exec --protocol wireguard --custom /run/secrets/${wgName}";
      # Пин satty на 0.20.1 — см. комментарий у инпута nixpkgs-satty в flake.nix
      # (в 0.21.x crop сломан: Ctrl+C копирует весь экран, а не выделение).
      pkgsSatty = import inputs.nixpkgs-satty { inherit (pkgs) system; };
      blurEnabled = config.services.niri.blur.enable;

      # v4 custom-commands plugin → v5 dmenu launcher entries. Each entry's `command`
      # emits the candidate line(s); on activation `exec` runs detached. A single static
      # line per entry reproduces the old one-shot launcher buttons.
      vpnEntry = id: label: glyph: cmd: {
        command = ''printf '%s\n' "${label}"'';
        exec = cmd;
        label = label;
        glyph = glyph;
        global = true;
      };
    in
    {
      imports = [ inputs.noctalia.homeModules.default ];

      # Package now comes from the noctalia flake (v5 build); the home module sets it via
      # mkDefault, so we no longer override with pkgs.noctalia-shell (nixpkgs ships v4.7.7).

      systemd.user.sessionVariables = {
        QT_QPA_PLATFORMTHEME = lib.mkForce "gtk3";
      };

      home.packages = [
        pkgs.qt6Packages.qt6ct
        pkgs.nwg-look
      ];

      programs.noctalia = {
        enable = true;
        systemd.enable = false;

        # Settings are written to ~/.config/noctalia/config.toml (v5 TOML schema).
        # validateConfig (default true) runs `noctalia config validate` at build time;
        # unknown keys are warnings, only hard errors fail the build.
        settings = {
          shell = {
            lang = "ru";
            corner_radius_scale = 0; # 0 = square corners (was radiusRatio/iRadiusRatio/boxRadiusRatio = 0)
            clipboard_auto_paste = "auto";
            animation.enabled = false; # was general.animationDisabled = true
            shadow.alpha = 0; # global shadow off (was general.enableShadows = false)
            panel = {
              shadow = false;
              transparency_mode = lib.mkIf blurEnabled (lib.mkForce "glass");
              # v5 split placement from position. launcher_placement is an enum of
              # only "attached" (drops from bar) | "floating"; the old "centered"
              # value (still in example.toml's stale comment) is unknown and gets
              # silently dropped, leaving the default. To put the launcher in the
              # screen middle use floating + launcher_position = "center".
              launcher_placement = "floating";
              launcher_position = "center";
            };
            screenshot = {
              pipe_to_command = true;
              pipe_command = "${pkgsSatty.satty}/bin/satty -f -"; # was appLauncher.screenshotAnnotationTool = "satty"
            };
            # v4 custom-commands (VPN launchers) → dmenu entries.
            launcher.dmenu.entry = {
              qutebrowser-vpn =
                vpnEntry "qutebrowser-vpn" "qutebrowser (VPN)" "circle-letter-q"
                  "${voponoExec} ${pkgs.qutebrowser}/bin/qutebrowser";
              telegram-vpn =
                vpnEntry "telegram-vpn" "Telegram (VPN)" "brand-telegram"
                  "${voponoExec} ${pkgs.ayugram-desktop}/bin/AyuGram";
              yandex-vpn =
                vpnEntry "yandex-vpn" "Yandex Browser (VPN)" "brand-yandex"
                  "${voponoExec} yandex-browser-stable";
              zen-vpn =
                vpnEntry "zen-vpn" "Zen Browser (VPN)" "circle-dot"
                  "${voponoExec} ${inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta}/bin/zen-beta";
            };
          };

          bar.main = {
            position = "top";
            radius = 0; # was bar.frameRadius
            capsule = true; # was bar.showCapsule
            # corner_radius_scale=0 squares panels/cards but NOT bar capsules:
            # capsules use resolvedBarCapsuleRadius, which defaults to a full pill
            # (min(w,h)/2) when capsule_radius is unset. 0 = square capsules/workspaces.
            capsule_radius = 0;
            widget_spacing = 2; # was bar.widgetSpacing
            padding = 0; # was bar.contentPadding
            # v5 renamed the geometry keys: margin_edge = gap to nearest screen
            # edge (top), margin_ends = inset at each end (left/right). The v4
            # names margin_v/margin_h are unknown in v5 and silently ignored,
            # leaving the defaults (180/10) that floated the bar off the edges.
            margin_edge = 0; # was bar.marginVertical / margin_v — pin to top
            margin_ends = 0; # was bar.marginHorizontal / margin_h — stretch to L/R edges
            shadow = false; # part of general.enableShadows = false
            background_opacity = lib.mkIf blurEnabled (lib.mkForce 0.7);
            capsule_opacity = lib.mkIf blurEnabled (lib.mkForce 0.7);

            start = [
              "sysmon"
              "clock"
              "media"
            ];
            center = [ "workspaces" ];
            end = [
              "tray"
              "keyboard_layout"
              "network"
            ]
            ++ lib.optional hasBluetooth "bluetooth"
            ++ [ "volume" ]
            ++ lib.optional isLaptop "brightness"
            ++ lib.optional isLaptop "battery"
            ++ [
              "notifications"
              "control-center"
            ];
          };

          # Per-widget settings (was the inline widget objects in v4 bar.widgets).
          widget = {
            keyboard_layout.show_icon = false;
            # Ширина медиа-виджета динамическая: он измеряет текст и делает
            # clamp(ширина_текста, min_length, max_length). min_length=0 убирает
            # добор пустотой на коротких названиях, большой max_length позволяет
            # длинным помещаться целиком (дефолты были 80/220).
            media.min_length = 0;
            media.max_length = 600;
            # chrono format inside {:...}. Time · date · short weekday (%a renders
            # in ru via shell.lang). tooltip_format shows the full date on hover.
            clock = {
              format = "{:%H:%M · %d.%m %a}";
              tooltip_format = "{:%A, %d %B %Y}";
            };
          };

          # theme.{mode,source,custom_palette} задаёт stylix-target noctalia
          # (stylix/modules/noctalia/hm.nix): source = "custom" с палитрой из
          # base16Scheme и mode из stylix.polarity. Здесь их дублировать нельзя —
          # апстрим пишет их без mkDefault, получается конфликт определений.
          # v4 templates.activeTemplates = ["telegram"] has no v5 builtin equivalent
          # (the telegram builtin template was dropped). Re-add as a user template if needed.

          notification.position = "bottom_right"; # was notifications.location

          osd.kinds = {
            # Was osd.enabledTypes = ["Volume" "Brightness" "LockKey"]; everything else off.
            volume = true;
            volume_output = true;
            volume_input = false; # off: pttkey (mic mute toggle) would spam the input OSD on every keypress
            brightness = true;
            lock_keys = true;
            wifi = false;
            bluetooth = false;
            power_profile = false;
            caffeine = false;
            nightlight = false;
            dnd = false;
            keyboard_layout = false; # was notifications.enableKeyboardLayoutToast = false
            media = false;
            privacy = false;
          };

          location.address = "Novosibirsk"; # was location.name

          dock.enabled = false;

          # Upstream noctalia (v5) renders the wallpaper itself (built-in C++
          # engine, no awww/swww). Point its default wallpaper at the stylix
          # image so stylix stays the single source of truth for the scheme's
          # wallpaper (config.stylix.image == scheme.image, e.g. assets/nord2.png).
          wallpaper = {
            enabled = true;
            default.path = "${config.stylix.image}";
          };
        };
      };
    };
}
