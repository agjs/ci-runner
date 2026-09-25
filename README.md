# ci-runner

GitHub Actions runner image for self-hosted runners in a home k3s cluster
([actions-runner-controller](https://github.com/actions/actions-runner-controller)).

`ghcr.io/actions/actions-runner` plus the tools GitHub-hosted Ubuntu runners
ship and workflows tend to assume: shellcheck, yamllint, zip, make/gcc,
pip/pipx, psql, rsync, wget, envsubst, kubectl, kustomize, helm, yq, gh,
Node.js 24 and Google Chrome —
plus bun pre-installed at `~/.bun/bin` so `oven-sh/setup-bun` skips its
download on a version match.

Published as `ghcr.io/agjs/ci-runner:<runner-version>-<build>`.

## Job-start hook

`/home/runner/hooks/job-started.sh` runs before each job when
`ACTIONS_RUNNER_HOOK_JOB_STARTED` points at it. If `CI_BUILDKIT_ENDPOINT` is
set (e.g. `tcp://buildkitd.ci-runners.svc.cluster.local:1234`), it makes that
remote BuildKit the default docker builder, so plain `docker build` and
`docker compose build` hit its persistent cache. Pair with
`BUILDX_DEFAULT_LOAD=1` so results land in the job's local docker. Falls back
to local builds if the endpoint is unreachable.
