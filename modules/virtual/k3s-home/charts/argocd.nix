{
  name = "argo-cd";
  targetNamespace = "argocd";
  createNamespace = true;
  repo = "https://argoproj.github.io/argo-helm";
  version = "9.1.7"; # pick the version you want
  hash = "sha256:7014017a6c327bd6c682ad71f866f4a0e11508a01e9c39af1b1d8151186cbd61";
  values = {
    global = {
      domain = "argocd.otohgunga.nl";
    };
    configs = {
      params = {
        "server.insecure" = true;
      };
    };
    server = {
      ingress = {
        enabled = true;
        ingressClassName = "nginx";
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt-dns";
          "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true";
          "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP";
          "gethomepage.dev/enabled" = "true";
          "gethomepage.dev/description" = "Control your deployments through a web interface.";
          "gethomepage.dev/group" = "System";
          "gethomepage.dev/icon" = "sh-argo-cd.svg";
          "gethomepage.dev/name" = "ArgoCD";
          "gethomepage.dev/app" = "argocd-server";
        };
        extraTls = [
          {
            hosts = [ "argocd.otohgunga.nl" ];
            secretName = "argocd-https-tls";
          }
        ];
      };
    };
  };
  extraDeploy = [
    {
      apiVersion = "argoproj.io/v1alpha1";
      kind = "Application";
      metadata = {
        name = "gitops-ctrl";
        namespace = "argocd";
      };
      spec = {
        project = "default";
        source = {
          repoURL = "https://github.com/sebastiaankok/k8s-homelab.git";
          path = "k8s/k3s-home/argocd";
          targetRevision = "HEAD";
          directory = {
            recurse = true;
            include = "*/application.yaml";
            jsonnet = {};
          };
        };
        destination = {
          name = "in-cluster";
          namespace = "argocd";
        };
        syncPolicy = {};
      };
    }
  ];
}
