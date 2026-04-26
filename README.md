<div align="center">

<img src="https://raw.githubusercontent.com/kubernetes/kubernetes/master/logo/logo.png" align="center" width="144px" height="144px"/>

### My Home Ops Repository

_... managed with ArgoCD, NixOS, and k3s_ <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16">

</div>

<div align="center">

[![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-blue?logo=argo&logoColor=white&style=for-the-badge)](https://argo-cd.readthedocs.io)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/badge/Kubernetes-k3s-blue?logo=kubernetes&logoColor=white&style=for-the-badge)](https://k3s.io)&nbsp;&nbsp;
[![NixOS](https://img.shields.io/badge/OS-NixOS-blue?logo=nixos&logoColor=white&style=for-the-badge)](https://nixos.org)&nbsp;&nbsp;

</div>

---

## 💡 Overview

This repository contains my **GitOps-driven homelab** powered by:

- **NixOS (flake-based)** for declarative host management
- **k3s** as the lightweight Kubernetes distribution
- **ArgoCD** for continuous reconciliation of Kubernetes manifests
- **Renovate** to keep applications / helm charts up-to-date

### ✅ Conventions & Notes
- Keep cluster-level bootstrap manifests (ArgoCD installation, Secrets, Cilium installation) at [nixos-microvm](https://github.com/sebastiaankok/home-ops/tree/main/modules/virtual/k3s-home).
- ArgoCD controller (apps-of-apps pattern) deploys chart and includes required values
- Secret management via `sops-nix`
- MicroVM support for lightweight VMs directly in Nix
- Nixvim-powered Neovim with LSP, treesitter, telescope, and more

With this setup, both my **infrastructure** and my **developer experience** live in a **single, version-controlled repo**.

---

## 🐧 NixOS

Beyond Kubernetes, this repo also manages my **NixOS machines** with flakes, ensuring everything is reproducible:

- **Server (i5-13600)** → runs k3s from a microVM and uses ArgoCD to deploy applications
- **Laptop (i5-7300U)** → development machine with workstation profile (Home Manager + Nixvim)
- **Raspberry Pi 4 (ser2net)** → low power device for exposing USB devices on the network

### 📂 Repo structure (NixOS side)

- **`flake.nix`** → defines hosts, inputs and modules
- **`flake.lock`** → pins inputs for reproducible builds
- **`hosts/`** → machine-specific configs (`b660-i5-13600/`, `dell-i5-7300U/`, `rpi4-ser2net/`)
- **`modules/`** → reusable service/system/microvm modules (e.g. `k3s-home/`, `prometheus/`)
- **`profiles/`** → role-based configs (e.g. `workstation.nix`)

---
## Bootstrap

```
## Install Cilium
helm install cilium cilium/cilium --version 1.18.6 -f k8s/k3s-home/argocd/system/cilium/values.yaml --namespace kube-system
## Install ArgoCD
helm install argo-cd oci://ghcr.io/argoproj/argo-helm/argo-cd --version 9.3.5 -f k8s/k3s-home/argocd/system/argocd/values.yaml --namespace argocd --create-namespace
kubectl apply -f k8s/k3s-home/argocd/system/argocd/controller.yaml
```
## ⚡ Adding new device

### Install nix-darwin (macbook)
Check [README.md](https://github.com/nix-darwin/nix-darwin?tab=readme-ov-file#prerequisites) on nix-darwin repo.
```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --prefer-upstream-nix
```

### Clone this repo
```bash
git clone https://github.com/sebastiaankok/home-ops.git
```
### Update flake.nix with new hardware

- Check your hostname and add this to the flake.nix file.
- Add your hardware specific config in it's own file, for example: `hosts/macbook-m5/default.nix`

### Rebuild from GitHub or local
Build and switch a host directly from this repo:

```bash
## Nixos from git directly
sudo nixos-rebuild switch --flake github:sebastiaankok/home-ops#HOSTNAME
## Darwin from local dir
sudo darwin-rebuild switch --flake.
```

### Manually updating flake lock files
```bash
nix flake update
## Or specific repo
nix flake update unstable
```

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f331/512.gif" alt="📜" width="20" height="20"> GitOps Layout

```sh
📁 k8s
└── 📁 k3s-home
    └── 📁 argocd
        ├── 📁 databases
        │   └── 📁 cnpg-operator
        │       └── application.yaml
        ├── 📁 home-automation
        │   ├── 📁 home-assistant
        │   ├── 📁 kamstrup-mqtt
        │   ├── 📁 mosquitto
        │   └── 📁 zigbee2mqtt
        ├── 📁 media
        │   ├── 📁 immich
        │   └── 📁 jellyfin
        ├── 📁 monitoring
        ├── 📁 network
        │   └── 📁 wol-proxy
        ├── 📁 nvr
        │   └── 📁 frigate
        └── 📁 system
            ├── 📁 cert-manager
            ├── 📁 ingress-nginx
            ├── 📁 ingress-nginx-media
            └── 📁 velero
```

---

## 📦 Backups

This homelab uses **Restic** to backup data directories.

### Restic (object storage)

```bash
export RESTIC_REPOSITORY="s3:s3.eu-central-003.backblazeb2.com/nix-restic/backups/data"
export $(sops -d modules/secrets.sops.yaml | yq .b2s3-config)
export "RESTIC_PASSWORD=$(sops -d modules/secrets.sops.yaml | yq .restic-repo-password)"

restic ls latests
```

---

## 🙏 Acknowledgements

This setup takes inspiration from the **HomeOps community** and builds on great projects like:
- [bjw-s-labs/helm-charts](https://github.com/bjw-s-labs/helm-charts)
- [nix-community/nixvim](https://github.com/nix-community/nixvim)
- [whazor/k8s-at-home-search](https://github.com/whazor/k8s-at-home-search)
