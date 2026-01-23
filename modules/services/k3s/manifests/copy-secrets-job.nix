{
  enable = true;
  target = "copy-secrets-job.yaml";
  content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "copy-secrets-to-manifests";
      namespace = "kube-system";
    };
    spec = {
      template = {
        spec = {
          restartPolicy = "OnFailure";
          containers = [
            {
              name = "copy-secrets";
              image = "busybox:latest";
              command = [
                "sh"
                "-c"
                ''
                  mkdir -p /manifests
                  cp /mounted-secrets/*.yaml /manifests/
                ''
              ];
              volumeMounts = [
                {
                  name = "secrets";
                  mountPath = "/mounted-secrets";
                }
                {
                  name = "k3s-manifests";
                  mountPath = "/manifests";
                }
              ];
            }
          ];
          volumes = [
            {
              name = "secrets";
              hostPath = {
                path = "/var/run/secrets/k3s-home";
                type = "Directory";
              };
            }
            {
              name = "k3s-manifests";
              hostPath = {
                path = "/var/lib/rancher/k3s/server/manifests";
                type = "Directory";
              };
            }
          ];
        };
      };
    };
  };
}
