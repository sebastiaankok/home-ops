{
  name = "argo-cd";
  targetNamespace = "argocd";
  createNamespace = true;
  repo = "https://argoproj.github.io/argo-helm";
  version = "9.3.5"; # pick the version you want
  hash = "sha256-CEQ9z/0qrfITM7zMb5abe+ihQ/C1fj5jgDd4DgBGmuo=";
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
  extraFieldDefinitions = {
    spec = {
      bootstrap = true;
    };
  };
}
