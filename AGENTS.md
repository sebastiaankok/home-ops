# AGENTS.md

## What this repo is

A single flake-based NixOS + nix-darwin repo that manages:
1. **NixOS/darwin hosts** — declarative machine configs rebuilt with `nixos-rebuild` / `darwin-rebuild`
2. **Kubernetes workloads** — k3s cluster running directly on `b660-i5-13600`, bootstrapped by Nix once, then managed by ArgoCD via GitOps

There are no traditional build/test/lint steps. Changes are applied by rebuilding Nix configurations or pushing to `main` for ArgoCD to reconcile.

## Repository layout

```
flake.nix              # Entrypoint — defines all hosts + inputs
hosts/<hostname>/      # Per-machine config (hardware, hostConfig options)
profiles/              # Role-based NixOS configs (server default, workstation)
modules/               # Shared NixOS modules + custom options (hostConfig.*)
  default.nix          # Declares hostConfig options (dataDir, user, interface, …)
  lib.nix              # Helper functions (mkRestic for backup definitions)
  services/k3s/        # k3s bootstrap: secrets, storage, gitops-ctrl manifest (active)
  virtual/k3s-home/    # Legacy MicroVM definition — not imported, kept for reference
home/modules/          # Home Manager config (shell, editor/nixvim, GUI apps)
k8s/k3s-home/argocd/  # ArgoCD Application manifests + Helm values (the GitOps tree)
.renovate/             # Renovate presets (automerge, commit-messages, groups, labels)
```

## Key commands

```bash
# Rebuild local darwin host
darwin-rebuild switch --flake .

# Rebuild a NixOS host (locally or remote)
sudo nixos-rebuild switch --flake .#<hostname>

# Rebuild from GitHub directly
sudo nixos-rebuild switch --flake github:sebastiaankok/home-ops#<hostname>

# Update all flake inputs
nix flake update

# Update a single input
nix flake update <input-name>
```

Hostnames defined in `flake.nix`: `b660-i5-13600`, `dell-i5-7300U`, `MacBook-Pro-van-Sebastiaan` (darwin).

## Secrets

- **sops-nix** with age encryption. Keys defined in `.sops.yaml`.
- Encrypted files match `*.sops.yaml` (scattered through `modules/`).
- Secrets are referenced via `sops.secrets."<name>".path` in Nix modules.
- Never commit decrypted secret values. To edit: `sops modules/secrets.sops.yaml` (requires the age key).

## Kubernetes / ArgoCD conventions

Full reference: **[`k8s/KUBERNETES.md`](k8s/KUBERNETES.md)**

- **Bootstrap model**: Nix (`modules/services/k3s/`) bootstraps the cluster once — it deploys the `gitops-ctrl` ArgoCD Application and injects secrets. ArgoCD and Cilium are **not** managed by Nix after bootstrap; they are self-managed via `k8s/k3s-home/argocd/system/`.
- k3s flags, secrets, and storage live in **`modules/services/k3s/`** — not in the `k8s/` tree.
- The `k8s/k3s-home/argocd/<category>/<app>/` directories each contain:
  - `application.yaml` — ArgoCD Application CR (multi-source with `$values` ref)
  - `values.yaml` — Helm values (start with bjw-s schema comment)
  - Optionally extra manifests: `namespace.yaml`, `local-storage.yaml`, `configmap.yaml`, `networkpolicy.yaml`
- Extra manifests are applied raw by ArgoCD; excluded from Helm via `directory.exclude`.
- ArgoCD sources reference `https://github.com/sebastiaankok/k8s-homelab.git` (same repo, different name on GitHub) with `ref: values` to resolve `$values/` paths.
- Most apps use the [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts) Helm chart.
- Always add `# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s-labs/helm-charts/refs/heads/main/charts/library/common/values.schema.json` as the first line of `values.yaml` for bjw-s apps.
- [kubesearch.dev](https://kubesearch.dev) is useful for finding example configs — results are in Flux `HelmRelease` format; extract the `spec.values` block into `values.yaml` and translate chart metadata into `application.yaml`.
- Sync waves (`argocd.argoproj.io/sync-wave`) control deployment order: `"1"` = infrastructure, `"3"` = apps.
- Renovate auto-updates Helm chart versions and container image tags in the `k8s/` tree.

## Adding a new Kubernetes app

See [`k8s/KUBERNETES.md`](k8s/KUBERNETES.md) for full templates and patterns. Summary:

1. Create `k8s/k3s-home/argocd/<category>/<app>/application.yaml` (multi-source with `$values` ref).
2. Create `k8s/k3s-home/argocd/<category>/<app>/values.yaml` with bjw-s schema comment at the top.
3. Add `namespace.yaml` / `local-storage.yaml` / `configmap.yaml` as needed.
4. If the app needs secrets, add them to `modules/services/k3s/secrets.sops.yaml` and register in `modules/services/k3s/k3s-secrets.nix`.
5. Push to `main` — ArgoCD reconciles automatically.

## Adding a new NixOS host

1. Add an entry in `flake.nix` under `nixosConfigurations` or `darwinConfigurations`.
2. Create `hosts/<hostname>/default.nix` with hardware config and `hostConfig` options.
3. Include relevant profiles and modules.

## Style notes

- Nix files use 2-space indentation.
- YAML files use 2-space indentation.
- Renovate handles dependency updates — do not manually bump versions that Renovate manages (Helm charts, container images, GitHub Actions).
