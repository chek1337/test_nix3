{ config, ... }:
let
  nixosMods = config.flake.modules.nixos;
  # Local HTTP+SOCKS port for the TUN-less "proxy" mode (1080 is wireproxy's).
  proxyPort = 2080;
  # Runtime-chosen domain keywords that bypass the tunnel. Lives in /run so it
  # is set per boot from the shell, not compiled into the system closure.
  directFile = "/run/singbox-ru.direct";
in
{
  flake.modules.nixos.singbox-ru =
    {
      config,
      pkgs,
      ...
    }:
    let
      # Both rule-sets taken from nixpkgs packages (local, no download needed).
      geoipRuSrs = "${pkgs.sing-geoip}/share/sing-box/rule-set/geoip-ru.srs";
      geositeRuSrs = "${pkgs.sing-geosite}/share/sing-box/rule-set/geosite-category-ru.srs";

      # Accepts either a vless:// URL or a WireGuard config on stdin and emits a
      # sing-box config. A VLESS upstream becomes a "proxy" outbound; a WireGuard
      # upstream becomes a "proxy" wireguard endpoint (sing-box >=1.11, endpoint
      # tags are usable as outbounds). The RU-direct routing is shared by both.
      #
      # argv[1] selects the inbound mode:
      #   tun    — system-wide transparent proxy (default)
      #   proxy  — no TUN at all, just a local HTTP+SOCKS port on 127.0.0.1,
      #            for per-app http_proxy/all_proxy (v2rayN "system proxy" style)
      # argv[2] is an optional comma-separated list of domain keywords kept off
      # the tunnel entirely — passed in at start time, never baked into the
      # config (see $SB_DIRECT / sb-direct in the shell helpers below).
      parserScript =
        pkgs.writeText "upstream-to-singbox-ru.py" # py
          ''
            import ipaddress
            import json
            import sys
            from urllib.parse import urlparse, parse_qs

            mode = sys.argv[1] if len(sys.argv) > 1 else "tun"
            if mode not in ("tun", "proxy"):
                sys.exit(f"unsupported mode: {mode!r} (expected 'tun' or 'proxy')")

            # Intranet keywords: never tunnelled, and resolved by the system's own
            # DNS — a public resolver knows nothing about corporate .loc names.
            raw_keywords = sys.argv[2] if len(sys.argv) > 2 else ""
            direct_keywords = [k.strip() for k in raw_keywords.split(",") if k.strip()]

            text = sys.stdin.read().strip()

            proxy_outbound = None
            proxy_endpoint = None
            server_bypass = []


            def bypass_rule(host):
                # The upstream server itself must not loop back through the tunnel.
                try:
                    ipaddress.ip_address(host)
                    return {"ip_cidr": [f"{host}/32"], "outbound": "direct"}
                except ValueError:
                    return {"domain": [host], "outbound": "direct"}


            def parse_vless(url):
                u = urlparse(url)
                q = {k: v[0] for k, v in parse_qs(u.query).items()}
                security = q.get("security", "none")
                sni = q.get("sni", u.hostname)
                transport_type = q.get("type", "tcp")

                ob = {
                    "type": "vless",
                    "tag": "proxy",
                    "server": u.hostname,
                    "server_port": u.port or 443,
                    "uuid": u.username,
                }
                flow = q.get("flow")
                if flow:
                    ob["flow"] = flow
                if security in ("tls", "reality"):
                    tls = {"enabled": True, "server_name": sni}
                    fp = q.get("fp")
                    if fp:
                        tls["utls"] = {"enabled": True, "fingerprint": fp}
                    if security == "reality":
                        tls["reality"] = {
                            "enabled": True,
                            "public_key": q["pbk"],
                            "short_id": q.get("sid", ""),
                        }
                    ob["tls"] = tls
                if transport_type == "ws":
                    ob["transport"] = {
                        "type": "ws",
                        "path": q.get("path", "/"),
                        "headers": {"Host": q.get("host", sni)},
                    }
                elif transport_type == "grpc":
                    ob["transport"] = {
                        "type": "grpc",
                        "service_name": q.get("serviceName", ""),
                    }
                return ob, [bypass_rule(u.hostname)]


            def parse_wireguard(cfg_text):
                section = None
                interface = {}
                peers = []
                cur = None
                for line in cfg_text.splitlines():
                    line = line.split("#", 1)[0].strip()
                    if not line:
                        continue
                    if line.startswith("[") and line.endswith("]"):
                        section = line[1:-1].strip().lower()
                        if section == "peer":
                            cur = {}
                            peers.append(cur)
                        continue
                    if "=" not in line:
                        continue
                    key, _, val = line.partition("=")
                    key = key.strip().lower()
                    val = val.strip()
                    if section == "interface":
                        interface[key] = val
                    elif section == "peer" and cur is not None:
                        cur[key] = val

                if "privatekey" not in interface:
                    sys.exit("wireguard config: missing [Interface] PrivateKey")
                if not peers:
                    sys.exit("wireguard config: no [Peer] section")
                addresses = [
                    a.strip() for a in interface.get("address", "").split(",") if a.strip()
                ]
                if not addresses:
                    sys.exit("wireguard config: missing [Interface] Address")

                endpoint = {
                    "type": "wireguard",
                    "tag": "proxy",
                    "system": False,
                    "address": addresses,
                    "private_key": interface["privatekey"],
                }
                if interface.get("mtu"):
                    endpoint["mtu"] = int(interface["mtu"])

                wg_peers = []
                bypass = []
                for p in peers:
                    ep = p.get("endpoint", "")
                    host, sep, port = ep.rpartition(":")
                    if not sep:
                        sys.exit(f"wireguard peer: bad Endpoint {ep!r}")
                    host = host.strip().strip("[]")
                    peer_obj = {
                        "address": host,
                        "port": int(port),
                        "public_key": p["publickey"],
                        "allowed_ips": [
                            a.strip()
                            for a in p.get("allowedips", "0.0.0.0/0, ::/0").split(",")
                            if a.strip()
                        ],
                    }
                    if p.get("presharedkey"):
                        peer_obj["pre_shared_key"] = p["presharedkey"]
                    if p.get("persistentkeepalive"):
                        peer_obj["persistent_keepalive_interval"] = int(
                            p["persistentkeepalive"]
                        )
                    wg_peers.append(peer_obj)
                    bypass.append(bypass_rule(host))
                endpoint["peers"] = wg_peers
                return endpoint, bypass


            if text.startswith("vless://"):
                proxy_outbound, server_bypass = parse_vless(text)
            elif "[interface]" in text.lower():
                proxy_endpoint, server_bypass = parse_wireguard(text)
            else:
                sys.exit("unsupported upstream: expected a vless:// URL or a WireGuard config")

            # routing_mark keeps sing-box's own egress out of its own TUN; without a
            # TUN there is nothing to escape from. It doubles as what makes this
            # outbound "non-empty" for the detour check below.
            direct = {"type": "direct", "tag": "direct"}
            if mode == "tun":
                direct["routing_mark"] = 100

            outbounds = [direct]
            if proxy_outbound is not None:
                outbounds.insert(0, proxy_outbound)

            if mode == "tun":
                inbounds = [
                    {
                        "type": "tun",
                        "tag": "tun-in",
                        "address": ["172.19.0.1/30"],
                        "auto_route": True,
                        "strict_route": False,
                        "stack": "gvisor",
                    }
                ]
                # sniff recovers the domain from the payload — without it a TUN
                # only ever sees IPs, and every domain rule below is dead weight.
                # Only a TUN can carry raw :53 traffic that needs hijacking.
                inbound_rules = [
                    {"action": "sniff"},
                    {"port": 53, "action": "hijack-dns"},
                ]
            else:
                inbounds = [
                    {
                        "type": "mixed",
                        "tag": "mixed-in",
                        "listen": "127.0.0.1",
                        "listen_port": ${toString proxyPort},
                    }
                ]
                # A SOCKS client may hand over a bare IP; sniff still helps there.
                inbound_rules = [{"action": "sniff"}]

            keyword_dns_rules = (
                [{"domain_keyword": direct_keywords, "server": "dns-local"}]
                if direct_keywords
                else []
            )
            keyword_route_rules = (
                [{"domain_keyword": direct_keywords, "outbound": "direct"}]
                if direct_keywords
                else []
            )

            cfg = {
                "log": {"level": "info", "timestamp": True},
                "dns": {
                    "servers": [
                        # No detour without a TUN: a DNS server with no detour dials
                        # through the OS directly, which is exactly what "direct"
                        # means here — and sing-box rejects a detour into a direct
                        # outbound that carries no dialer options at all. Under a TUN
                        # the detour is required instead, so the query rides the
                        # marked socket and does not loop back into the tunnel.
                        {
                            "type": "udp",
                            "tag": "dns-direct",
                            "server": "77.88.8.8",
                            **({"detour": "direct"} if mode == "tun" else {}),
                        },
                        {
                            "type": "udp",
                            "tag": "dns-proxy",
                            "server": "1.1.1.1",
                            "detour": "proxy",
                        },
                        # The host's own resolver (resolv.conf / DHCP) — the only
                        # one that knows intranet zones like .loc.
                        {"type": "local", "tag": "dns-local"},
                    ],
                    "rules": [
                        *keyword_dns_rules,
                        {"rule_set": ["geosite-ru"], "server": "dns-direct"},
                    ],
                    "final": "dns-proxy",
                    "strategy": "ipv4_only",
                },
                "inbounds": inbounds,
                "outbounds": outbounds,
                "route": {
                    "rule_set": [
                        {
                            "type": "local",
                            "tag": "geoip-ru",
                            "format": "binary",
                            "path": "${geoipRuSrs}",
                        },
                        {
                            "type": "local",
                            "tag": "geosite-ru",
                            "format": "binary",
                            "path": "${geositeRuSrs}",
                        },
                    ],
                    "rules": [
                        *inbound_rules,
                        *keyword_route_rules,
                        {"ip_is_private": True, "outbound": "direct"},
                        *server_bypass,
                        {"rule_set": ["geoip-ru"], "outbound": "direct"},
                        {"rule_set": ["geosite-ru"], "outbound": "direct"},
                    ],
                    "final": "proxy",
                    "auto_detect_interface": True,
                    "default_domain_resolver": "dns-direct",
                },
            }
            if proxy_endpoint is not None:
                cfg["endpoints"] = [proxy_endpoint]

            json.dump(cfg, sys.stdout, indent=2)
          '';
      # Resolve the runtime-selected config source ($2 = systemd instance %I):
      # an absolute path is used as-is, anything else is a sops secret name.
      # $1 is the inbound mode (tun|proxy), $3 the generated config's path.
      prepareScript = pkgs.writeShellScript "singbox-ru-prepare" ''
        mode="$1"
        src="$2"
        out="$3"
        case "$src" in
          /*) ;;
          *) src="/run/secrets/$src" ;;
        esac
        if [ ! -r "$src" ]; then
          echo "singbox-ru: config source not readable: $src" >&2
          exit 1
        fi
        # Runtime direct-domain list, written by the sb-direct shell helper right
        # before start. Absent file = no exceptions; nothing is baked into the
        # closure, so the list can change without a rebuild.
        keywords=""
        if [ -r ${directFile} ]; then
          keywords="$(tr -d '[:space:]' < ${directFile})"
        fi
        # Write through a temp file: a parser failure must not leave a truncated
        # config behind for ExecStart to pick up (redirection alone would).
        tmp="$out.tmp"
        if ! ${pkgs.python3}/bin/python3 ${parserScript} "$mode" "$keywords" < "$src" > "$tmp"; then
          rm -f "$tmp"
          echo "singbox-ru: failed to parse upstream config: $src" >&2
          exit 1
        fi
        chmod 600 "$tmp"
        mv -f "$tmp" "$out"
      '';
    in
    {
      # Both secret modules are cheap (just sops.secrets declarations); import
      # both so either upstream can be selected at runtime without rebuilding.
      imports = [
        nixosMods.unblock-vless-secret
        nixosMods.unblock-wg-secrets
      ];

      # Templated unit — the instance (%I) picks the config source at start:
      #   singbox-ru@<secret-name>   -> /run/secrets/<secret-name>
      #   singbox-ru@<escaped-path>  -> that file (systemd-escape'd absolute path)
      # The parser auto-detects VLESS vs WireGuard, so one template serves both.
      systemd.services."singbox-ru@" = {
        description = "sing-box transparent proxy (%I) — RU direct, rest tunnelled";
        after = [
          "network-online.target"
          "sops-nix.service"
        ];
        wants = [ "network-online.target" ];
        # No wantedBy — start manually with: sb-up [config]
        restartIfChanged = false;

        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = 5;
          RuntimeDirectory = "singbox-ru";
          RuntimeDirectoryMode = "0700";

          # %I is expanded by systemd in the directive value and passed as $2
          # (specifiers are not substituted inside the referenced script body).
          ExecStartPre = "${prepareScript} tun %I /run/singbox-ru/config.json";

          ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /run/singbox-ru/config.json";

          ExecStopPost = pkgs.writeShellScript "singbox-ru-cleanup" ''
            rm -f /run/singbox-ru/config.json
          '';
        };
      };

      # Same upstream selection, no TUN: sing-box only listens on
      # 127.0.0.1:${toString proxyPort} (HTTP + SOCKS on one port), so nothing is
      # captured system-wide and apps opt in via http_proxy/all_proxy. This is
      # v2rayN's "system proxy" mode minus the global toggle — per-app instead.
      # Runs alongside singbox-ru@ without conflict (different unit, own runtime
      # dir), but there is no point in having both up at once.
      systemd.services."singbox-ru-proxy@" = {
        description = "sing-box local HTTP/SOCKS proxy (%I) — RU direct, rest tunnelled";
        after = [
          "network-online.target"
          "sops-nix.service"
        ];
        wants = [ "network-online.target" ];
        # No wantedBy — start manually with: sb-proxy-up [config]
        restartIfChanged = false;

        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = 5;
          RuntimeDirectory = "singbox-ru-proxy";
          RuntimeDirectoryMode = "0700";

          ExecStartPre = "${prepareScript} proxy %I /run/singbox-ru-proxy/config.json";

          ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /run/singbox-ru-proxy/config.json";

          ExecStopPost = pkgs.writeShellScript "singbox-ru-proxy-cleanup" ''
            rm -f /run/singbox-ru-proxy/config.json
          '';
        };
      };
    };

  flake.modules.homeManager.singbox-ru =
    { config, pkgs, ... }:
    let
      # Default config for a bare `sb-up`, from settings.singboxRuUpstream.
      defaultCfg =
        if config.settings.singboxRuUpstream == "wireguard" then
          config.settings.wireguardConfigName
        else
          "vless-chumakov";
      escape = "${pkgs.systemd}/bin/systemd-escape";
      baseNoProxy = "127.0.0.1,localhost,::1";
    in
    {
      # ── Usage ────────────────────────────────────────────────────────────
      # Transparent proxy: RU (geoip-ru + geosite-ru) stays direct, everything
      # else goes through the chosen upstream. The upstream is picked at RUNTIME
      # (vopono-style) — no rebuild needed to switch configs.
      #
      #   sb-up                       # default upstream (settings.singboxRuUpstream)
      #   sb-up wireguard-desktop-home  # a sops secret name -> /run/secrets/<name>
      #   sb-up vless-chumakov          # VLESS secret (VLESS vs WG auto-detected)
      #   sb-file /path/to/any.conf     # an arbitrary config file (not in sops)
      #
      #   sb-status                   # is it up? which instance?
      #   sb-config                   # dump the generated /run/singbox-ru/config.json
      #   sb-logs [cfg]               # follow the journal
      #   sb-restart [cfg]            # re-apply / swap upstream
      #   sb-down                     # stop the tunnel
      #
      # Per-app mode (no TUN) — v2rayN's "system proxy" without Enable Tun:
      # sing-box only listens on 127.0.0.1:${toString proxyPort}, nothing is
      # captured globally, and each app opts in through the proxy env vars.
      #
      #   sb-proxy-up [cfg]           # start the local HTTP/SOCKS proxy
      #   sb-proxy-down               # stop it
      #   sb-proxy-status             # is it up? which instance?
      #   sb-proxy-config             # dump /run/singbox-ru-proxy/config.json
      #   sb-proxy-logs [cfg]         # follow the journal
      #
      #   sbx <cmd> [args...]         # run one command through the proxy
      #   sb-env / sb-env-off         # toggle proxy vars in the current shell
      #
      # Keeping intranet domains off the tunnel, decided at RUNTIME — nothing
      # about them is compiled into the system:
      #
      #   export SB_DIRECT="eltex,corp.local"   # shell variable, picked up on start
      #   sb-direct eltex                       # or set it explicitly for this boot
      #   sb-direct                             # show what is currently in effect
      #   sb-direct -c                          # clear it
      #   sb-proxy-up / sb-up                   # (re)start to apply
      #
      # The keywords are substring matches on the domain, so "eltex" covers
      # eltex.loc, gerrit.eltex.loc, … Those names also get resolved by the
      # host's own DNS instead of a public resolver, which is the only way an
      # intranet zone resolves at all.
      #
      # Notes:
      #   • Only one system-wide TUN at a time — sb-up drops any running instance.
      #   • Plain WireGuard only; AmneziaWG configs won't work (use vopono/awg).
      #   • Don't combine with a full-tunnel wg-full-up / vopono.
      #   • sbx only covers apps that honour http_proxy/all_proxy; for the rest
      #     use the TUN mode (sb-up) or vopono's netns.
      #   • no_proxy is suffix-matched by clients, so a bare "eltex" there would
      #     miss gerrit.eltex.loc — that is why the real exception lives in
      #     sing-box's routing, which matches the substring properly.
      # ─────────────────────────────────────────────────────────────────────
      programs.zsh.shellAliases = {
        # Only one system-wide TUN runs at a time, so down/status/config are
        # instance-agnostic.
        sb-down = "sudo systemctl stop 'singbox-ru@*.service'";
        sb-status = "systemctl status 'singbox-ru@*.service'";
        sb-config = "sudo cat /run/singbox-ru/config.json";

        sb-proxy-down = "sudo systemctl stop 'singbox-ru-proxy@*.service'";
        sb-proxy-status = "systemctl status 'singbox-ru-proxy@*.service'";
        sb-proxy-config = "sudo cat /run/singbox-ru-proxy/config.json";
      };

      programs.zsh.initContent = ''
        # Runtime config selection, in the spirit of vopono --custom:
        #   sb-up                 -> default upstream (${defaultCfg})
        #   sb-up <secret-name>   -> /run/secrets/<secret-name>  (e.g. sb-up wireguard-desktop-home)
        #   sb-up /abs/path.conf  -> that file directly (also: sb-file <path>)
        # VLESS vs WireGuard is auto-detected from the config contents.
        # Always systemd-escape: %I un-escapes it back (turning "-" into "/"),
        # so an un-escaped name like foo-bar would wrongly become foo/bar.
        _sb_instance() { ${escape} -- "$1"; }

        # Domain keywords that must skip the tunnel, chosen at runtime. Handed to
        # the units through ${directFile}, which the prepare step reads at start;
        # $SB_DIRECT (if exported) is the implicit source, sb-direct the explicit one.
        #   export SB_DIRECT="eltex,corp.local"   -> applied by the next sb-*-up
        #   sb-direct eltex corp.local            -> set for this boot
        #   sb-direct                             -> show
        #   sb-direct -c                          -> clear
        sb-direct() {
          if [[ "$1" == "-c" ]]; then
            sudo rm -f ${directFile}
            unset SB_DIRECT
            echo "direct keywords: (none)"
            return
          fi
          if (( $# == 0 )); then
            local current
            current="$(cat ${directFile} 2>/dev/null)"
            echo "direct keywords: ''${current:-(none)}"
            [[ -n "$SB_DIRECT" && "$SB_DIRECT" != "$current" ]] &&
              echo "\$SB_DIRECT is \"$SB_DIRECT\" — restart with sb-proxy-up/sb-up to apply"
            return
          fi
          # Accept both "sb-direct a b c" and "sb-direct a,b,c".
          local joined="''${(j:,:)@}"
          export SB_DIRECT="$joined"
          _sb_write_direct "$joined"
          echo "direct keywords: $joined (restart with sb-proxy-up/sb-up to apply)"
        }
        _sb_write_direct() {
          if [[ -n "$1" ]]; then
            printf '%s' "$1" | sudo tee ${directFile} >/dev/null
          else
            sudo rm -f ${directFile}
          fi
        }
        # Only overwrite the runtime file when this shell actually has an opinion:
        # an unset SB_DIRECT means "leave whatever sb-direct configured alone",
        # while an empty one is an explicit "no exceptions".
        _sb_apply_direct() {
          [[ -n "''${SB_DIRECT+x}" ]] && _sb_write_direct "$SB_DIRECT"
          return 0
        }

        sb-up() {
          local cfg="''${1:-${defaultCfg}}"
          local inst; inst="$(_sb_instance "$cfg")"
          _sb_apply_direct
          # Drop any running instance first to keep a single active TUN.
          sudo sh -c "systemctl stop 'singbox-ru@*.service' 2>/dev/null; \
            systemctl start 'singbox-ru@$inst.service'"
        }
        sb-file() { sb-up "$1"; }
        sb-restart() { sb-up "''${1:-${defaultCfg}}"; }
        sb-logs() {
          local cfg="''${1:-${defaultCfg}}"
          journalctl -u "singbox-ru@$(_sb_instance "$cfg").service" -f
        }

        # ── TUN-less mode: local HTTP/SOCKS proxy, opt-in per application ────
        export SB_PROXY_URL="http://127.0.0.1:${toString proxyPort}"
        export SB_SOCKS_URL="socks5h://127.0.0.1:${toString proxyPort}"

        sb-proxy-up() {
          local cfg="''${1:-${defaultCfg}}"
          local inst; inst="$(_sb_instance "$cfg")"
          _sb_apply_direct
          sudo sh -c "systemctl stop 'singbox-ru-proxy@*.service' 2>/dev/null; \
            systemctl start 'singbox-ru-proxy@$inst.service'" || return 1
          echo "proxy up on $SB_PROXY_URL — use: sbx <cmd>, or sb-env in this shell"
          local active; active="$(cat ${directFile} 2>/dev/null)"
          if [[ -n "$active" ]]; then
            echo "direct (no tunnel): $active"
          fi
        }
        sb-proxy-logs() {
          local cfg="''${1:-${defaultCfg}}"
          journalctl -u "singbox-ru-proxy@$(_sb_instance "$cfg").service" -f
        }

        # Whatever is in $SB_DIRECT is also worth keeping out of the proxy at the
        # client level, so apps that resolve intranet names themselves never even
        # open a connection to sing-box for them. Suffix matching applies here, so
        # a full zone ("eltex.loc") works while a bare keyword ("eltex") does not —
        # the substring case is covered by sing-box's own routing.
        _sb_no_proxy() { printf '%s' "${baseNoProxy}''${SB_DIRECT:+,$SB_DIRECT}"; }

        # Run a single command through the proxy, leaving the shell untouched.
        sbx() {
          if (( $# == 0 )); then
            echo "usage: sbx <cmd> [args...]" >&2
            return 2
          fi
          local np; np="$(_sb_no_proxy)"
          http_proxy="$SB_PROXY_URL" https_proxy="$SB_PROXY_URL" \
            HTTP_PROXY="$SB_PROXY_URL" HTTPS_PROXY="$SB_PROXY_URL" \
            all_proxy="$SB_SOCKS_URL" ALL_PROXY="$SB_SOCKS_URL" \
            no_proxy="$np" NO_PROXY="$np" \
            "$@"
        }

        # Same vars, but for everything started from this shell from now on.
        sb-env() {
          export http_proxy="$SB_PROXY_URL" https_proxy="$SB_PROXY_URL"
          export HTTP_PROXY="$SB_PROXY_URL" HTTPS_PROXY="$SB_PROXY_URL"
          export all_proxy="$SB_SOCKS_URL" ALL_PROXY="$SB_SOCKS_URL"
          local np; np="$(_sb_no_proxy)"
          export no_proxy="$np" NO_PROXY="$np"
          echo "shell proxy: $SB_PROXY_URL (no_proxy: $np)"
        }
        sb-env-off() {
          unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY \
            all_proxy ALL_PROXY no_proxy NO_PROXY
          echo "shell proxy: off"
        }
      '';
    };
}
