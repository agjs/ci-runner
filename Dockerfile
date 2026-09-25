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
ARG NODE_VERSION=v24.21.0

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

# Node.js (hosted runners preinstall it; e.g. tinkercaster's agent runtime
# test spawns `node` for the Vite dev server).
RUN set -eux; \
    curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz" \
      | tar -xJ --strip-components=1 -C /usr/local; \
    node --version; npm --version; npx --version

# Google Chrome stable (hosted runners preinstall it; Lighthouse CI and
# other headless-browser tooling look for it on the standard path).
RUN set -eux; \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends google-chrome-stable; \
    rm -rf /var/lib/apt/lists/*; \
    google-chrome --version
ENV CHROME_PATH=/usr/bin/google-chrome

# Playwright's Chromium system libraries, so `playwright install --with-deps`
# in jobs finds them already present. Browsers themselves are version-bound
# and cached separately (the cluster mounts a shared PLAYWRIGHT_BROWSERS_PATH).
ARG PLAYWRIGHT_VERSION=1.63.0
RUN npx -y "playwright@${PLAYWRIGHT_VERSION}" install-deps chromium \
 && rm -rf /var/lib/apt/lists/* /root/.npm

# Job-start hook: route docker builds to a shared BuildKit when available.
COPY --chmod=755 hooks/job-started.sh /home/runner/hooks/job-started.sh

# GitHub-hosted runners allow `pip install --user` against the system
# Python; Ubuntu 24.04 blocks it by default (PEP 668). Match hosted
# behaviour — jobs install pinned tools into ~/.local in a throwaway pod.
ENV PIP_BREAK_SYSTEM_PACKAGES=1

USER runner

# Bun pre-installed where oven-sh/setup-bun looks first (~/.bun/bin/bun):
# on a version match it uses it with no download or cache restore at all
# (setup-bun src/action.ts). Keep in step with the repos' pinned bun; on a
# mismatch setup-bun just downloads as usual.
ARG BUN_VERSION=1.4.2
RUN curl -fsSLo /tmp/bun.zip "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip" \
 && unzip -q /tmp/bun.zip -d /tmp \
 && mkdir -p ~/.bun/bin \
 && mv /tmp/bun-linux-x64/bun ~/.bun/bin/bun \
 && ln -s bun ~/.bun/bin/bunx \
 && rm -rf /tmp/bun.zip /tmp/bun-linux-x64 \
 && ~/.bun/bin/bun --revision

# Fail the build if a --user install into ~/.local/bin doesn't work.
RUN pip install --user --no-cache-dir yamllint==1.38.0 \
 && ~/.local/bin/yamllint --version \
 && pip uninstall -y yamllint >/dev/null
