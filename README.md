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

## ⚡ Usage

### Install from GitHub
Build and switch a host directly from this repo:
```bash
sudo nixos-rebuild switch --flake github:sebastiaankok/home-ops#HOSTNAME
```

Build from local
```bash
cd ~/nix-config
nixos-rebuild switch --flake .
```

Manually updating flake lock files
```bash
nix flake update
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
        ├── 📁 downloads
        │   ├── 📁 bazarr
        │   ├── 📁 jellyseerr
        │   ├── 📁 prowlarr
        │   ├── 📁 radarr
        │   ├── 📁 sabnzbd
        │   └── 📁 sonarr
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

This homelab uses **Velero** and **Kopia** to backup Kubernetes resources and persistent data.

### Velero (Kubernetes resources)
- Velero handles cluster-level backups for namespaces, deployments, ConfigMaps, and Secrets.
- Backups can be restored via:
```bash
velero restore create --from-backup <backup>
```

### Kopia (object storage)
Kopia connects to object storage (e.g., Backblaze B2) to snapshot PVs and local storage used by apps like media servers, databases, and home automation.
```bash

export AWS_ACCESS_KEY_ID="" AWS_ACCESS_KEY_SECRET="" KOPIA_PASSWORD=""

kopia repository connect s3 \
  --bucket <bucket> \
  --region eu-central-003 \
  --endpoint s3.eu-central-003.backblazeb2.com \
  --prefix kopia/<namespace>/
```

---

## 🙏 Acknowledgements

This setup takes inspiration from the **HomeOps community** and builds on great projects like:
- [bjw-s-labs/helm-charts](https://github.com/bjw-s-labs/helm-charts)
- [nix-community/nixvim](https://github.com/nix-community/nixvim)
- [whazor/k8s-at-home-search](https://github.com/whazor/k8s-at-home-search)
