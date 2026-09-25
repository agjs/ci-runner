# ci-runner

GitHub Actions runner image for self-hosted runners in a home k3s cluster
([actions-runner-controller](https://github.com/actions/actions-runner-controller)).

`ghcr.io/actions/actions-runner` plus the tools GitHub-hosted Ubuntu runners
ship and workflows tend to assume: shellcheck, yamllint, zip, make/gcc,
pip/pipx, psql, rsync, wget, envsubst, kubectl, kustomize, helm, yq, gh —
plus bun pre-installed at `~/.bun/bin` so `oven-sh/setup-bun` skips its
download on a version match.

Published as `ghcr.io/agjs/ci-runner:<runner-version>-<build>`.
