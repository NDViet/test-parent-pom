#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGE_NAME="${1:-ndviet/test-automation-java-base}"
SYNC_SCRIPT="${SCRIPT_DIR}/java-base/sync-maven-seed.sh"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required but was not found in PATH"
  exit 1
fi

if [ ! -x "${SYNC_SCRIPT}" ]; then
  echo "Seed sync script not found or not executable: ${SYNC_SCRIPT}"
  exit 1
fi

REVISION="${REVISION:-$(sed -n 's|.*<revision>\([^<]*\)</revision>.*|\1|p' "${PROJECT_ROOT}/pom.xml" | head -n 1)}"
if [ -z "${REVISION}" ]; then
  echo "Could not resolve <revision> from ${PROJECT_ROOT}/pom.xml"
  exit 1
fi

echo "[java-base] Syncing Maven seed POM from parent pom.xml"
"${SYNC_SCRIPT}"

echo "[java-base] Building image ${IMAGE_NAME} with tags: latest, ${REVISION}"
docker build \
  -f "${PROJECT_ROOT}/containers/java-base/Dockerfile" \
  -t "${IMAGE_NAME}:latest" \
  -t "${IMAGE_NAME}:${REVISION}" \
  "${PROJECT_ROOT}"

echo "[java-base] Build completed:"
echo "  - ${IMAGE_NAME}:latest"
echo "  - ${IMAGE_NAME}:${REVISION}"
