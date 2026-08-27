{ config, lib, pkgs, ... }:
with lib;

let
  app = "prometheus";
  cfg = config.hostConfig.services.${app};
  appData = config.hostConfig.dataDir + "/${app}";
in
{

  options.hostConfig.services.${app} = {
    enable = mkEnableOption "${app}";
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
      default = false;
    };
  };

  config = mkIf cfg.enable {

    sops.secrets."services/${app}/password" = {
      sopsFile = ./secrets.sops.yaml;
      owner = app;
      restartUnits = [ "${app}.service" ];
    };

    sops.secrets."services/${app}/scrape_hass" = {
      sopsFile = ./secrets.sops.yaml;
      owner = app;
      restartUnits = [ "${app}.service" ];
    };

    services.${app} = {
      enable = true;
      checkConfig = "syntax-only";
      enableReload = true;
      enableAgentMode = true;
      exporters = {
        node = {
          enable = true;
          extraFlags = [
            "--no-collector.softnet"
            "--no-collector.schedstat"
            "--collector.netclass.ignored-devices=^(cilium_|lxc|cali|veth|dummy|tunl|kube|vxlan|cbr|docker|flannel|geneve)"
            "--collector.filesystem.mount-points-include=^(/|/storage)$"
          ];
        };
        smartctl = {
          enable = true;
          devices = [ "/dev/sda" "/dev/nvme0n1" ];
        };
      };

      scrapeConfigs = [
        {
          job_name = "${config.networking.hostName}-node";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
              ];
                labels.instance = config.networking.hostName;
            }
          ];
        }
        {
          job_name = "${config.networking.hostName}-smartctl";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}"
              ];
                labels.instance = config.networking.hostName;
            }
          ];
        }
        {
          job_name = "${config.networking.hostName}-hass";
          bearer_token_file = config.sops.secrets."services/${app}/scrape_hass".path;
          scrape_interval = "60s";
          metrics_path = "/api/prometheus";

          static_configs = [
            {
              targets = [
                "127.0.0.1:8123"
              ];
                labels.instance = config.networking.hostName;
            }
          ];
        }
      ];

      remoteWrite = [
        {
          name = "grafana-cloud";
          url = "https://prometheus-prod-24-prod-eu-west-2.grafana.net/api/prom/push";
          basic_auth = {
            username = "1680587";
            password_file = config.sops.secrets."services/${app}/password".path;
          };
        }
      ];
    };

    services.restic.backups = mkIf cfg.backup (config.lib.hostConfig.mkRestic {
     inherit app appData;
     paths = [ appData ];
    });
  };
}
