{
  name = "cilium";
  targetNamespace = "kube-system"; # Cilium usually runs in kube-system
  repo = "https://helm.cilium.io/";
  version = "1.18.6";
  hash = "sha256-+yr38lc5X1+eXCFE/rq/K0m4g/IiNFJHuhB+Nu24eUs=";
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
      bootstrap = true;
    };
  };
}

