# Claude Code workstation: the image behind the claude-workstation namespace on
# the home k3s cluster (manifests/platform/claude-workstation in
# argocd-app-of-apps). The owner SSHes in from a phone (over WireGuard or the
# LAN), or Mosh for a session that survives network changes and phone sleep,
# and lands in a tmux session running interactive Claude Code. sshd runs
# as the non-root `claude` user on port 2222; its config is written by the
# pod's entrypoint.
#
# Everything a session may need is baked in, so the pod never installs tools
# at start-up. Versions are pinned; bump them deliberately, and keep
# CLAUDE_CODE_VERSION in step with the image tag built by CI.
# trixie, not bookworm: Worktrunk needs Git 2.43+ and bookworm ships 2.39.
FROM debian:trixie-slim

ARG CLAUDE_CODE_VERSION=2.1.296
ARG NODE_VERSION=v24.22.1
ARG BUN_VERSION=1.4.2
ARG KUBECTL_VERSION=v1.36.2
ARG KUSTOMIZE_VERSION=v5.8.1
ARG HELM_VERSION=v4.3.0
ARG GH_VERSION=2.101.0
ARG VAULT_VERSION=2.0.2
ARG WORKTRUNK_VERSION=v0.80.0
ARG WORKTRUNK_SHA256=532ce3ed5eecb1be274c925b5887f61671e2434a4ca2561b9a8ac9379dbba199

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      git \
      jq \
      mosh \
      openssh-client \
      openssh-server \
      python3 \
      ripgrep \
      tmux \
      unzip \
      xz-utils \
      yamllint \
 && rm -rf /var/lib/apt/lists/*

# Node.js LTS (the Claude Code CLI and npm live here).
RUN set -eux; \
    curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz" \
      | tar -xJ --strip-components=1 -C /usr/local; \
    node --version; npm --version

# Claude Code, pinned. Auto-update is disabled in the Deployment so the
# running version only changes with an image rebuild.
RUN set -eux; \
    npm install -g --no-audit --no-fund "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"; \
    claude --version

RUN set -eux; \
    curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip" -o /tmp/bun.zip; \
    unzip -q /tmp/bun.zip -d /tmp; \
    install -m 0755 /tmp/bun-linux-x64/bun /usr/local/bin/bun; \
    ln -s bun /usr/local/bin/bunx; \
    rm -rf /tmp/bun.zip /tmp/bun-linux-x64; \
    bun --version

RUN set -eux; \
    curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
    chmod 0755 /usr/local/bin/kubectl; \
    kubectl version --client

RUN set -eux; \
    curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
      | tar -xz -C /usr/local/bin kustomize; \
    kustomize version

RUN set -eux; \
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
      | tar -xz --strip-components=1 -C /usr/local/bin linux-amd64/helm; \
    helm version

RUN set -eux; \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" \
      | tar -xz --strip-components=2 -C /usr/local/bin "gh_${GH_VERSION}_linux_amd64/bin/gh"; \
    gh --version

RUN set -eux; \
    curl -fsSLo /tmp/vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"; \
    unzip -q /tmp/vault.zip -d /usr/local/bin vault; \
    rm -f /tmp/vault.zip; \
    vault version

# Worktrunk (wt): one git worktree per task, so parallel Claude sessions in the
# same repo never share a checkout. Checksum pinned with the version.
RUN set -eux; \
    curl -fsSLo /tmp/wt.tar.xz "https://github.com/max-sixty/worktrunk/releases/download/${WORKTRUNK_VERSION}/worktrunk-x86_64-unknown-linux-musl.tar.xz"; \
    echo "${WORKTRUNK_SHA256}  /tmp/wt.tar.xz" | sha256sum -c -; \
    tar -xJf /tmp/wt.tar.xz -C /tmp; \
    install -m 0755 /tmp/worktrunk-x86_64-unknown-linux-musl/wt /tmp/worktrunk-x86_64-unknown-linux-musl/git-wt /usr/local/bin/; \
    rm -rf /tmp/wt.tar.xz /tmp/worktrunk-x86_64-unknown-linux-musl; \
    wt --version

# Non-root owner of the persistent home volume (/home/claude).
RUN useradd --create-home --uid 1000 --shell /bin/bash claude \
 && mkdir -p /home/claude/work \
 && chown -R 1000:1000 /home/claude

# sshd (running as claude, so no privilege separation) needs its privsep dir to
# exist at start-up. /run is read-only in the pod, so it is created here.
RUN mkdir -p /run/sshd && chmod 0755 /run/sshd

USER 1000:1000
WORKDIR /home/claude
ENV HOME=/home/claude \
    TERM=xterm-256color \
    TMUX_TMPDIR=/tmp \
    DISABLE_AUTOUPDATER=1

EXPOSE 2222

CMD ["bash"]
