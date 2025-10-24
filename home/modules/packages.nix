{pkgs, ...}:
{
  nixpkgs.config = { allowUnfree = true; };

  home.packages = with pkgs; [
    # languages
    python3
    python3Packages.pip
    pipx
    virtualenv
    go

    ## language utils
    black
    isort
    djlint
    nixfmt-classic
    prettierd
    shellcheck
    stylua
    taplo
    yamlfmt
    ansible-lint

    # system tools
    bash
    findutils
    yq-go
    jq
    coreutils-full
    gnugrep
    gnused
    tree
    nettools
    vivid
    diff-so-fancy
    ripgrep
    eza
    lazygit
    btop
    nh
    sops
    watch

    # network
    nmap
    wireguard-go
    wireguard-tools

    # databases
    postgresql
    minio-client
    kafkactl

    ## containers
    docker-client
    podman
    colima

    ## ci tools
    gitleaks
    rclone
    restic
    ssh-to-age

    ## k8s
    k9s
    kubectl
    kubecolor
    krew
    stern
    cilium-cli
    kubernetes-helm
    helm-ls
    argocd
    velero
    kopia
    kopia-ui

    ## ai
    aider-chat-full

    ## gui
    moonlight-qt
    signal-desktop
    obsidian
  ];
}
