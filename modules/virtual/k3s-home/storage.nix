{ config, ... }:
{
  systemd.services.dailyBackup = {
    description = "Daily backup of /data to /storage/backups";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        /run/current-system/sw/bin/rsync -av --exclude='/library' --exclude='/frigate/frigate' /data/ /storage/backups/
      '';
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.timers.dailyBackup = {
    description = "Run dailyBackup service every day 6 hour interval";
    timerConfig = {
      #OnCalendar = "12:00";
      OnCalendar = [ "06:00" "12:00" "18:00" ];
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  services.restic = {
    enable = true;

    backups = {
      "data-b2" = {
        paths = [ "/data" ];

        # Global exclude file
        excludes = [
          "/library"

          # Logs
          "/logs/*"
          "home-assistant.log*"

          "frigate/clips/*"
          "frigate/frigate/*"
          "frigate/model_cache/*"
          "frigate/exports/*"

          # Caches
          "**/cache/**"
          "**/metadata/**"

          # SQLite journals globally
          "**/logs.db"
          "**/*.db-shm"
          "**/*.db-wal"
        ];

        # B2 repository
        repository = "s3:s3.eu-central-003.backblazeb2.com/nix-restic/backups/data";

        # Secrets
        passwordFile = config.sops.secrets."restic-repo-password".path;
        environmentFile = config.sops.secrets."b2s3-config".path;

        # Retention policy
        pruneOpts = [
          "--keep-daily" "7"
          "--keep-weekly" "1"
          "--keep-monthly" "1"
          "--keep-yearly" "0"
        ];

        timerConfig.OnCalendar = "06:00";
        timerConfig.Persistent = true;
      };
    };
  };

}
