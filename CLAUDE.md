# AGENTS.md

## What this repo is

A single flake-based NixOS + nix-darwin repo that manages:
1. **NixOS/darwin hosts** — declarative machine configs rebuilt with `nixos-rebuild` / `darwin-rebuild`
2. **Kubernetes workloads** — k3s cluster running inside a NixOS microVM, apps deployed via ArgoCD

There are no traditional build/test/lint steps. Changes are applied by rebuilding Nix configurations or pushing to `main` for ArgoCD to reconcile.

## Repository layout

```
flake.nix              # Entrypoint — defines all hosts + inputs
hosts/<hostname>/      # Per-machine config (hardware, hostConfig options)
profiles/              # Role-based NixOS configs (server default, workstation)
modules/               # Shared NixOS modules + custom options (hostConfig.*)
  default.nix          # Declares hostConfig options (dataDir, user, interface, …)
  lib.nix              # Helper functions (mkRestic for backup definitions)
  services/            # NixOS service modules (k3s, prometheus) — opt-in via hostConfig
  virtual/k3s-home/    # MicroVM definition for the k3s cluster (bootstrap, secrets, storage)
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

- Cluster bootstrap (ArgoCD, Cilium, k3s flags, secret injection) lives in **`modules/virtual/k3s-home/`** and **`modules/services/k3s/`** — not in the `k8s/` tree.
- The `k8s/k3s-home/argocd/<category>/<app>/` directories each contain:
  - `application.yaml` — ArgoCD Application CR
  - `values.yaml` — Helm values
  - Optionally extra manifests (excluded from Helm via `directory.exclude`)
- ArgoCD sources reference `https://github.com/sebastiaankok/k8s-homelab.git` (same repo, different name on GitHub) with `ref: values` to resolve `$values/` paths.
- Most apps use the [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts) Helm chart. Check `application.yaml` for chart source and version.
- Sync waves (`argocd.argoproj.io/sync-wave`) control deployment order.
- Renovate auto-updates Helm chart versions and container image tags in the `k8s/` tree.

## Adding a new Kubernetes app

1. Create `k8s/k3s-home/argocd/<category>/<app>/application.yaml` following the existing pattern (multi-source with `$values` ref).
2. Create `k8s/k3s-home/argocd/<category>/<app>/values.yaml` with Helm values.
3. If the app needs secrets, add them to `modules/virtual/k3s-home/secrets.sops.yaml` and register in `k3s-secrets.nix`.

## Adding a new NixOS host

1. Add an entry in `flake.nix` under `nixosConfigurations` or `darwinConfigurations`.
2. Create `hosts/<hostname>/default.nix` with hardware config and `hostConfig` options.
3. Include relevant profiles and modules.

## Style notes

- Nix files use 2-space indentation.
- YAML files use 2-space indentation.
- Renovate handles dependency updates — do not manually bump versions that Renovate manages (Helm charts, container images, GitHub Actions).
