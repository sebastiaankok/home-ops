{
  name = "cilium";
  targetNamespace = "kube-system"; # Cilium usually runs in kube-system
  repo = "https://helm.cilium.io/";
  version = "1.18.4";
  hash = "sha256:NqqIK+KjWsafcI9uYuHh+XX/SMVhzgedNa01cYKEryI=";
  values = {
    operator.replicas = 1;
    hubble.ui.enabled = true;
    hubble.relay.enabled = true;
    ipam.operator.clusterPoolIPv4PodCIDRList = "10.42.0.0/16";
    tunnelProtocol = "geneve";
    l2announcements.enabled = true;
    l2announcements.leaseDuration = "120s";
    l2announcements.leaseRenewDeadline = "60s";
    l2announcements.leaseRetryPeriod = "10s";
    externalIPs.enabled = true;
    #nodePort.enabled=true
    #kubeProxyReplacement = true;
    #k8sServiceHost = "127.0.0.1";
    #k8sServicePort = 6443;
  };
  extraFieldDefinitions = {
    spec = {
      repo = "https://helm.cilium.io/";
      chart = "cilium";
      version = "1.18.1";
      bootstrap = true;
    };
  };
  extraDeploy = [
    {
      apiVersion = "cilium.io/v2";
      kind = "CiliumLoadBalancerIPPool";
      metadata = {
        name = "all";
      };
      spec = {
        blocks = [
          {
            start = "10.10.21.30";
            stop  = "10.10.21.100";
          }
        ];
      };
    }
    {
      apiVersion = "cilium.io/v2alpha1";
      kind = "CiliumL2AnnouncementPolicy";
      metadata = {
        name = "policy-all";
      };
      spec = {
        interfaces = [ "^ens[0-9]+" "enp0s[0-9]+" ];
        externalIPs = true;
        loadBalancerIPs = true;
      };
    }
  ];
}

