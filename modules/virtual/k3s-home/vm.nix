{ cfg, lib, ... }:

{
  hypervisor = cfg.vm.hypervisor;
  vcpu = cfg.vm.cpu;
  mem = cfg.vm.memory;
  vsock.cid = 3;
  volumes = [
    {
      mountPoint = "/var/lib/rancher";
      image = "var-k3s.img";
      size = 100 * 1024;
    }
    {
      mountPoint = "/etc/rancher";
      image = "etc-k3s.img";
      size = 1024;
    }
  ];
  interfaces = [
    {
      id = "${cfg.vm.hostname}";
      mac = "${cfg.vm.mac}";
      type = "macvtap";
      macvtap  = {
        link = "${cfg.vm.interface}";
        mode = "${cfg.vm.network_mode}";
      };
    }
  ];

  shares = [
    {
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
      tag = "ro-store";
      proto = "virtiofs";
    }
    {
      source = "/data";
      mountPoint = "/data";
      tag = "k8s-home";
      proto = "virtiofs";
    }
    {
      source = "/var/run/secrets/${cfg.app}";
      mountPoint = "/var/run/secrets";
      tag = "${cfg.app}-sops";
      proto = "virtiofs";
    }
    {
      source = "/storage/library";
      mountPoint = "/storage/library";
      tag = "library";
      proto = "virtiofs";
    }
  ];
}
