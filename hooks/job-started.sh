#!/usr/bin/env bash
# Runs before every job (the cluster sets ACTIONS_RUNNER_HOOK_JOB_STARTED to
# this file). When the cluster provides a shared BuildKit
# (CI_BUILDKIT_ENDPOINT), make it the default builder so plain
# `docker build` / `docker compose build` reuse its persistent layer cache
# instead of building from scratch in the job's empty dind. The cluster also
# sets BUILDX_DEFAULT_LOAD=1 so results are loaded back into dind and can be
# run. If the endpoint is unreachable, builds stay local.
set -u
[ -n "${CI_BUILDKIT_ENDPOINT:-}" ] || exit 0

if docker buildx create --name k3s --driver remote "$CI_BUILDKIT_ENDPOINT" >/dev/null 2>&1 \
  && timeout 20 docker buildx inspect --bootstrap k3s >/dev/null 2>&1; then
  docker buildx use --default --global k3s
  echo "Default docker builder: shared BuildKit at $CI_BUILDKIT_ENDPOINT"
else
  docker buildx rm k3s >/dev/null 2>&1 || true
  echo "::warning::Shared BuildKit at $CI_BUILDKIT_ENDPOINT unreachable; docker builds run locally"
fi
exit 0
