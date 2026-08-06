{pkgs, pkgs-unstable, ...}:
{
  home.packages = with pkgs; [
    # languages
    python3
    python3Packages.pip
    pipx
    virtualenv
    uv
    go
    nodejs

    ## language utils
    black
    isort
    djlint
    nixfmt
    prettierd
    shellcheck
    stylua
    taplo
    yamlfmt
    yamllint
    gnumake
    # ansible-lint
    ansible-lint
    pandoc
    pre-commit
    glow

    # system tools
    fzf
    t-rec
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
    colordiff
    ripgrep
    eza
    btop
    nh
    sops
    watch

    # git
    git-filter-repo
    gh
    glab
    lazygit
    delta

    # network
    nmap
    wireguard-go
    wireguard-tools
    iperf3

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
    kubernetes-helmPlugins.helm-unittest
    kubeconform
    helm-ls
    argocd
    velero
    kopia
    kubefwd
    trivy
    kind

    ## gui
    moonlight-qt
    obsidian
    mqtt-explorer
  ];
}
