# GitHub Actions runner for the home k3s cluster (actions-runner-controller).
#
# The upstream actions-runner image is deliberately minimal; GitHub-hosted
# ubuntu runners ship a large toolset that workflows quietly rely on. This
# adds the common gaps so jobs behave the same on either.
FROM ghcr.io/actions/actions-runner:2.336.0

ARG KUBECTL_VERSION=v1.36.2
ARG KUSTOMIZE_VERSION=v5.8.1
ARG HELM_VERSION=v4.3.0
ARG YQ_VERSION=v4.53.6
ARG GH_VERSION=2.101.0

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      gettext-base \
      make \
      pipx \
      postgresql-client \
      python3-pip \
      python3-venv \
      rsync \
      shellcheck \
      wget \
      xz-utils \
      yamllint \
      zip \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
    curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | tar -xz -C /usr/local/bin kustomize; \
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar -xz --strip-components=1 -C /usr/local/bin linux-amd64/helm; \
    curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"; \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" | tar -xz --strip-components=2 -C /usr/local/bin "gh_${GH_VERSION}_linux_amd64/bin/gh"; \
    chmod +x /usr/local/bin/kubectl /usr/local/bin/yq; \
    for t in kubectl kustomize helm yq gh shellcheck yamllint zip make gcc pipx psql rsync envsubst wget; do command -v "$t"; done

USER runner
