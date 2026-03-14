#!/usr/bin/env bash
set -euo pipefail

SEED_REPO_DIR="${SEED_REPO_DIR:-/opt/m2-seed/repository}"
TARGET_REPO_DIR="${TARGET_REPO_DIR:-/root/.m2/repository}"
SEED_MARKER="${TARGET_REPO_DIR}/.seeded-from-test-parent-pom"

if [ "${SEED_M2_REPO:-true}" = "true" ] && [ -d "${SEED_REPO_DIR}" ]; then
  mkdir -p "${TARGET_REPO_DIR}"
  if [ ! -f "${SEED_MARKER}" ]; then
    echo "[java-base] Seeding Maven repository from test-parent-pom cache image"
    cp -a "${SEED_REPO_DIR}/." "${TARGET_REPO_DIR}/"
    touch "${SEED_MARKER}"
  fi
fi

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
cd "${WORKSPACE_DIR}"

if [ "$#" -eq 0 ]; then
  exec bash
fi

if [ "${FORCE_MAVEN_OFFLINE:-true}" = "true" ] && [ "$1" = "mvn" ]; then
  set -- mvn -o "${@:2}"
fi

if [ "${FORCE_GRADLE_OFFLINE:-true}" = "true" ] && { [ "$1" = "gradle" ] || [ "$1" = "./gradlew" ] || [ "$1" = "gradlew" ]; }; then
  set -- "$1" --offline "${@:2}"
fi

echo "[java-base] Working directory: $(pwd)"
echo "[java-base] Executing: $*"
exec "$@"
