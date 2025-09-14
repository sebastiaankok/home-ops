{ cfg, pkgs, pkgs-unstable, ... }:
{
  networking = {
    nftables.enable = true;
    firewall = {
      enable = false;
    };
  };

  services.k3s = {
    enable = true;
    package = pkgs-unstable.k3s_1_33;
    role = "server";
    gracefulNodeShutdown.enable = true;

    extraFlags = [
      "--disable traefik"
      "--disable local-storage"
      "--disable servicelb"
      "--disable-network-policy"
      "--flannel-backend=none"
      #"--disable-kube-proxy"
    ];


    autoDeployCharts = {
      argocd = import ./charts/argocd.nix;
      cilium = import ./charts/cilium.nix;
    };

    # -- Install secrets (mounted sops directory)
    manifests = {
      copy-secrets-job = import ./manifests/copy-secrets-job.nix;
    };
  };
}
