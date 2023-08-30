{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.create_ap;
  configFile = pkgs.writeText "create_ap.conf" (generators.toKeyValue { } cfg.settings);
  clearState = pkgs.writeShellScript "clear-ap-state" ''
    rm -rf /tmp/create_ap.*.lock
    rm -rf /tmp/create_ap.wlp1s0.conf.*
    rm -rf /tmp/create_ap.common.conf/ifaces/*
'';
in {
  options = {
    services.create_ap = {
      enable = mkEnableOption (lib.mdDoc "setup wifi hotspots using create_ap");
      settings = mkOption {
        type = with types; attrsOf (oneOf [ int bool str ]);
        default = {};
        description = lib.mdDoc ''
          Configuration for `create_ap`.
          See [upstream example configuration](https://raw.githubusercontent.com/lakinduakash/linux-wifi-hotspot/master/src/scripts/create_ap.conf)
          for supported values.
        '';
        example = {
          INTERNET_IFACE = "eth0";
          WIFI_IFACE = "wlan0";
          SSID = "My Wifi Hotspot";
          PASSPHRASE = "12345678";
        };
      };
    };
  };

  config = mkIf cfg.enable {

    systemd = {
      services.create_ap = {
        wantedBy = [ "multi-user.target" ];
        description = "Create AP Service";
        after = [ "network.target" ];
        preStart = lib.concatStringsSep "\n" [ clearState ];
        restartTriggers = [ configFile ];
        serviceConfig = {
          ExecStart = "${pkgs.linux-wifi-hotspot}/bin/create_ap --config ${configFile}";
          KillSignal = "SIGINT";
          Restart = "on-failure";
        };
      };
    };

  };

  meta.maintainers = with lib.maintainers; [ onny ];

}
