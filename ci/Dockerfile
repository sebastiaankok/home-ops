# syntax=docker/dockerfile:1
FROM ghcr.io/home-operations/actions-runner:2.334.0@sha256:95d91d7f8d241e319ef2f4fec08f417aa1606b96fbb327643f75c303acd30002
USER root
RUN \
    apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get -qq install -y --no-install-recommends \
      python3.14 python3.14-dev python3.14-venv && \
    python3.14 -m ensurepip --upgrade && \
    rm -rf /var/lib/apt/lists/*
# Node.js LTS
RUN \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get -qq install -y --no-install-recommends nodejs && \
    npm install --no-save @commitlint/cli @commitlint/config-conventional && \
    rm -rf /var/lib/apt/lists/*

# Playwright system dependencies
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN \
    python3.14 -m pip install playwright && \
    python3.14 -m playwright install-deps chromium && \
    python3.14 -m playwright install chromium && \
    rm -rf /root/.cache/pip

# CLI tools: existing + argocd
RUN \
    apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends jq yamllint && \
    curl -fsSL "https://github.com/yannh/kubeconform/releases/download/v0.7.0/kubeconform-linux-amd64.tar.gz" \
      | tar xz -C /usr/local/bin kubeconform && \
    curl -fsSL "https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz" \
      | tar xz --strip-components=1 -C /usr/local/bin linux-amd64/helm && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64" \
      -o /usr/local/bin/yq && \
    curl -sSL -o /usr/local/bin/argocd \
      "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64" && \
    chmod +x /usr/local/bin/kubeconform /usr/local/bin/helm /usr/local/bin/yq /usr/local/bin/argocd && \
    rm -rf /var/lib/apt/lists/*
USER runner
