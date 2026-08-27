{ config, lib, ...}:
{
  config = {
    hostConfig = {
      dataDir = "/data";
      user = "sebastiaan";
      interface = "enp3s0";
      sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOTvwNAE0ZUIgEZRlZqw48o5Sw8gZuCPaYUPUHEp/vtg sebastiaan@linux.com";
      services = {
        # system
        # prometheus is now deployed via ArgoCD (k8s/k3s-home/argocd/monitoring/prometheus/)
        prometheus.enable = false;
      };
    };

    # Raise file descriptor and inotify limits for root systemd user manager
    systemd.settings.Manager.DefaultLimitNOFILE = 65536;
    boot.kernel.sysctl = {
      "fs.inotify.max_user_watches" = 65536;
      "fs.file-max" = 500000;
      "net.ipv4.ip_forward" = 1;
    };
  };

  imports = [
    ./hardware-configuration.nix
  ];
}
