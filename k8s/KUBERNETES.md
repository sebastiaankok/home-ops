# Kubernetes / ArgoCD Reference

## Layout

```
k8s/k3s-home/argocd/
  <category>/
    <app>/
      application.yaml   # ArgoCD Application CR (required)
      values.yaml        # Helm values (required for Helm apps)
      namespace.yaml     # Namespace manifest (optional)
      local-storage.yaml # PV + PVC definitions (optional)
      configmap.yaml     # ConfigMap for app config (optional)
      networkpolicy.yaml # NetworkPolicy (optional)
      *.yaml             # Any extra raw manifests (optional)
```

Categories in use: `databases`, `development`, `games`, `home-automation`, `media`, `monitoring`, `network`, `nvr`, `system`.

Extra manifests (anything that's not `application.yaml` or `values.yaml`) are applied directly by ArgoCD alongside the Helm release. They're excluded from Helm template processing via `directory.exclude` in `application.yaml`.

---

## ArgoCD Application pattern

Every app uses a **multi-source** Application: one source provides the raw manifests and the `$values` ref, the other is the Helm chart.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <app-name>
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "3"
spec:
  project: default
  syncPolicy:
    automated:
      prune: true
  destination:
    name: in-cluster
    namespace: <namespace>
  sources:
    - repoURL: 'https://github.com/sebastiaankok/k8s-homelab.git'
      targetRevision: main
      ref: values
      path: "k8s/k3s-home/argocd/<category>/<app>/"
      directory:
        exclude: '{application.yaml,values.yaml}'
    - chart: app-template
      repoURL: 'https://bjw-s-labs.github.io/helm-charts'
      targetRevision: 4.6.2
      helm:
        releaseName: "<app-name>"
        valueFiles:
          - $values/k8s/k3s-home/argocd/<category>/<app>/values.yaml
```

Key points:
- `repoURL` is always `https://github.com/sebastiaankok/k8s-homelab.git` (the GitHub name of this repo).
- `ref: values` on the first source makes `$values` available to the second source.
- `directory.exclude` prevents `application.yaml` and `values.yaml` from being applied as raw manifests.
- Add `syncOptions: [CreateNamespace=true]` when the namespace is not managed by a separate `namespace.yaml`.
- Add `syncOptions: [ServerSideApply=true]` for CRD-heavy operators (e.g. cnpg).

### Sync waves

Lower wave = deploys first. Typical assignment:
- `"1"` — namespaces, CRDs, cluster infrastructure (cert-manager, ingress-nginx, cloudflared)
- `"2"` — operators that other apps depend on
- `"3"` — regular applications

---

## bjw-s app-template

Most apps use the [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts) chart. Always add the schema declaration as the first line of `values.yaml` for editor validation:

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s-labs/helm-charts/refs/heads/main/charts/library/common/values.schema.json
```

### Core structure

```yaml
controllers:
  <controller-name>:        # matches releaseName by convention, or "main"
    containers:
      app:
        image:
          repository: ghcr.io/owner/image
          tag: 1.2.3
        resources:
          requests:
            cpu: 10m
            memory: 128Mi
          limits:
            memory: 512Mi
        securityContext:
          runAsUser: 1000
          runAsGroup: 1000
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop: [ALL]

service:
  app:
    controller: <controller-name>
    ports:
      http:
        port: 8080

ingress:
  app:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-dns
    hosts:
      - host: myapp.otohgunga.nl
        paths:
          - path: /
            service:
              identifier: app
              port: http
            pathType: Prefix
    tls:
      - hosts: [myapp.otohgunga.nl]
        secretName: myapp-https-tls

persistence:
  data:
    existingClaim: local-myapp-pvc
    globalMounts:
      - path: /data
  tmpfs:
    type: emptyDir
    globalMounts:
      - path: /tmp
        subPath: myapp-tmp
  config-file:
    type: configMap
    name: myapp-config
    advancedMounts:
      <controller-name>:
        app:
          - path: /config/config.yaml
            subPath: config.yaml
```

### Homepage integration

Add these ingress annotations to show the app in the homepage dashboard:

```yaml
gethomepage.dev/enabled: "true"
gethomepage.dev/name: "App Name"
gethomepage.dev/icon: "icon-slug"
gethomepage.dev/description: Short description
gethomepage.dev/group: "Category Name"
```

---

## Finding app configurations with kubesearch.dev

[kubesearch.dev](https://kubesearch.dev) is a search engine for home-lab Kubernetes configurations. Use it to find example configs for apps.

**Important:** kubesearch.dev results show Flux `HelmRelease` format. This repo uses ArgoCD. You must translate the values — the Helm values themselves are identical, but the wrapper differs:

| Flux HelmRelease | This repo |
|---|---|
| `spec.values:` block | `values.yaml` file content |
| `spec.chart.spec.chart:` | `chart:` in `application.yaml` sources |
| `spec.chart.spec.version:` | `targetRevision:` in `application.yaml` |
| `spec.chart.spec.sourceRef:` | `repoURL:` in `application.yaml` |

Example — Flux format from kubesearch.dev:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
spec:
  chart:
    spec:
      chart: app-template
      version: 4.6.2
      sourceRef:
        kind: HelmRepository
        name: bjw-s
  values:
    controllers:
      myapp:
        containers:
          app:
            image:
              repository: ghcr.io/owner/myapp
              tag: 1.0.0
```

Translates to `values.yaml`:
```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s-labs/helm-charts/refs/heads/main/charts/library/common/values.schema.json
controllers:
  myapp:
    containers:
      app:
        image:
          repository: ghcr.io/owner/myapp
          tag: 1.0.0
```

And `application.yaml` sources:
```yaml
    - chart: app-template
      repoURL: 'https://bjw-s-labs.github.io/helm-charts'
      targetRevision: 4.6.2
```

---

## Local storage (PV + PVC)

When an app needs persistent storage backed by the node's local disk, create a `local-storage.yaml` with a PV and PVC pair:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-<app>-pv
  namespace: <namespace>
  labels:
    app.kubernetes.io/name: <app>
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  storageClassName: local-<app>
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  local:
    path: "/data/<app>"
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values: [k3s-home, b660-i5-13600]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: local-<app>-pvc
  namespace: <namespace>
  labels:
    app.kubernetes.io/name: <app>
spec:
  storageClassName: local-<app>
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
```

Reference in `values.yaml`:
```yaml
persistence:
  data:
    existingClaim: local-<app>-pvc
```

---

## Secrets

Kubernetes Secrets are injected at cluster bootstrap level, not in the `k8s/` tree. To add a secret for an app:

1. Add the secret value to `modules/services/k3s/secrets.sops.yaml` (edit with `sops`).
2. Register it in `modules/services/k3s/k3s-secrets.nix` so it's written to the cluster on bootstrap.
3. Reference the Secret name in `values.yaml` (e.g. via `envFrom` or `env.valueFrom`).

---

## Non-app-template apps

Not all apps use bjw-s app-template. Some use upstream Helm charts directly (cert-manager, ingress-nginx, velero, cnpg). The `application.yaml` pattern is the same — only the `chart`, `repoURL`, and `targetRevision` differ. `values.yaml` follows the upstream chart's schema (no bjw-s schema comment needed).

---

## Checklist: adding a new app

1. Pick a category directory (or create one).
2. Create `application.yaml` from the multi-source template above.
3. Create `values.yaml` with the bjw-s schema comment at the top.
4. If the app needs a namespace not auto-created: add `namespace.yaml`.
5. If the app needs local persistent storage: add `local-storage.yaml`.
6. If the app needs a config file: add `configmap.yaml` and mount it via `persistence` in `values.yaml`.
7. If the app needs secrets: follow the secrets steps above.
8. Push to `main` — ArgoCD reconciles automatically.

---

## Bootstrap model

Nix is used **once** to get the cluster to a functional state. After that, all upgrades and configuration changes flow through ArgoCD via this git repo.

### What Nix does (modules/services/k3s/)

- Configures k3s flags, disables built-in servicelb/traefik/flannel
- Injects Kubernetes Secrets (via sops-nix) before ArgoCD starts
- Deploys the `gitops-ctrl` ArgoCD Application as a raw k3s manifest — this is the single seed that tells ArgoCD where to find the `k8s/` tree

### What ArgoCD does (this tree)

Everything else. The `gitops-ctrl` Application recursively picks up all `*/application.yaml` files under `k8s/k3s-home/argocd/` and creates the corresponding Applications. This includes ArgoCD itself (`system/argocd/`) and Cilium (`system/cilium/`), which are self-managed.

### Fresh cluster bootstrap procedure

On a new cluster where no ArgoCD or Cilium is running yet:

1. **Deploy Cilium** (CNI must exist before any pod can start):
   ```bash
   # Reference chart config: modules/services/k3s/charts/cilium.nix
   helm install cilium https://helm.cilium.io/ \
     --namespace kube-system \
     --version 1.18.6 \
     -f <(helm show values cilium/cilium)  # then apply values from cilium.nix
   ```

2. **Deploy ArgoCD**:
   ```bash
   # Reference chart config: modules/services/k3s/charts/argocd.nix
   kubectl create namespace argocd
   helm install argo-cd argo-cd \
     --repo https://argoproj.github.io/argo-helm \
     --namespace argocd \
     --version 9.3.5
   ```

3. **Apply Nix config** (`nixos-rebuild switch`) — this writes `gitops-ctrl` to the k3s manifests directory, which ArgoCD then picks up.

4. ArgoCD syncs the `k8s/` tree and takes over managing ArgoCD and Cilium going forward.

### Migrating from k3s HelmChart CRs to ArgoCD management

If the cluster previously had `autoDeployCharts` for ArgoCD or Cilium (k3s Helm controller managed them), remove the k3s HelmChart CRs **before** applying the Nix change that removes them from config. If you remove them from Nix first, k3s auto-deploy deletes the CRs and the Helm controller uninstalls the charts.

Safe migration order:
```bash
# 1. Strip finalizers so Helm controller skips uninstall on deletion
kubectl patch helmchart argocd -n kube-system --type=merge -p '{"metadata":{"finalizers":[]}}'
kubectl delete helmchart argocd -n kube-system

kubectl patch helmchart cilium -n kube-system --type=merge -p '{"metadata":{"finalizers":[]}}'
kubectl delete helmchart cilium -n kube-system

# 2. Then apply the Nix rebuild
sudo nixos-rebuild switch --flake .#b660-i5-13600
```

ArgoCD picks up the new Applications from the `k8s/` tree and manages the releases from that point on.
