# syntax=docker/dockerfile:1
FROM ghcr.io/home-operations/actions-runner:2.334.0@sha256:95d91d7f8d241e319ef2f4fec08f417aa1606b96fbb327643f75c303acd30002

COPY --from=gcr.io/kaniko-project/executor:v1.23.2 /kaniko /kaniko

USER root

RUN \
    apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends jq yamllint && \
    curl -fsSL "https://github.com/yannh/kubeconform/releases/download/v0.7.0/kubeconform-linux-amd64.tar.gz" \
      | tar xz -C /usr/local/bin kubeconform && \
    curl -fsSL "https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz" \
      | tar xz --strip-components=1 -C /usr/local/bin linux-amd64/helm && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64" \
      -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/kubeconform /usr/local/bin/helm /usr/local/bin/yq && \
    rm -rf /var/lib/apt/lists/*

USER runner
