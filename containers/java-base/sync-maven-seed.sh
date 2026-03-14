#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PARENT_POM="${PROJECT_ROOT}/pom.xml"
SEED_POM="${SCRIPT_DIR}/maven-seed/pom.xml"

if ! command -v xmllint >/dev/null 2>&1; then
  echo "xmllint is required but was not found in PATH"
  exit 1
fi

if [ ! -f "${PARENT_POM}" ]; then
  echo "Parent POM not found: ${PARENT_POM}"
  exit 1
fi

PARENT_REVISION="$(xmllint --xpath "string(/*[local-name()='project']/*[local-name()='properties']/*[local-name()='revision'])" "${PARENT_POM}")"
if [ -z "${PARENT_REVISION}" ]; then
  echo "Could not resolve <revision> from ${PARENT_POM}"
  exit 1
fi

TMP_OUTPUT="$(mktemp)"
SEEN_KEYS="$(mktemp)"
trap 'rm -f "${TMP_OUTPUT}" "${SEEN_KEYS}"' EXIT

append_dependency() {
  local group_id="$1"
  local artifact_id="$2"
  local version="$3"
  local scope="$4"
  local type="$5"
  local classifier="$6"
  local include_version="$7"

  if [ -z "${group_id}" ] || [ -z "${artifact_id}" ]; then
    return
  fi

  local key="${group_id}|${artifact_id}|${version}|${scope}|${type}|${classifier}|${include_version}"
  if grep -Fqx "${key}" "${SEEN_KEYS}"; then
    return
  fi
  echo "${key}" >> "${SEEN_KEYS}"

  cat >> "${TMP_OUTPUT}" <<EOF
        <dependency>
            <groupId>${group_id}</groupId>
            <artifactId>${artifact_id}</artifactId>
EOF
  if [ "${include_version}" = "true" ] && [ -n "${version}" ]; then
    cat >> "${TMP_OUTPUT}" <<EOF
            <version>${version}</version>
EOF
  fi
  if [ -n "${scope}" ]; then
    cat >> "${TMP_OUTPUT}" <<EOF
            <scope>${scope}</scope>
EOF
  fi
  if [ -n "${type}" ]; then
    cat >> "${TMP_OUTPUT}" <<EOF
            <type>${type}</type>
EOF
  fi
  if [ -n "${classifier}" ]; then
    cat >> "${TMP_OUTPUT}" <<EOF
            <classifier>${classifier}</classifier>
EOF
  fi
  cat >> "${TMP_OUTPUT}" <<EOF
        </dependency>
EOF
}

append_dependencies_from_xpath() {
  local xpath="$1"
  local include_version="$2"
  local count
  count="$(xmllint --xpath "count(${xpath})" "${PARENT_POM}")"
  count="${count%.*}"
  if [ -z "${count}" ] || [ "${count}" -eq 0 ]; then
    return
  fi

  local i
  for ((i = 1; i <= count; i++)); do
    local base="(${xpath})[${i}]"
    local group_id artifact_id version scope type classifier
    group_id="$(xmllint --xpath "string(${base}/*[local-name()='groupId'])" "${PARENT_POM}")"
    artifact_id="$(xmllint --xpath "string(${base}/*[local-name()='artifactId'])" "${PARENT_POM}")"
    version="$(xmllint --xpath "string(${base}/*[local-name()='version'])" "${PARENT_POM}")"
    scope="$(xmllint --xpath "string(${base}/*[local-name()='scope'])" "${PARENT_POM}")"
    type="$(xmllint --xpath "string(${base}/*[local-name()='type'])" "${PARENT_POM}")"
    classifier="$(xmllint --xpath "string(${base}/*[local-name()='classifier'])" "${PARENT_POM}")"
    append_dependency "${group_id}" "${artifact_id}" "${version}" "${scope}" "${type}" "${classifier}" "${include_version}"
  done
}

append_plugins_from_xpath() {
  local xpath="$1"
  local count
  count="$(xmllint --xpath "count(${xpath})" "${PARENT_POM}")"
  count="${count%.*}"
  if [ -z "${count}" ] || [ "${count}" -eq 0 ]; then
    return
  fi

  local i
  for ((i = 1; i <= count; i++)); do
    local base="(${xpath})[${i}]"
    local group_id artifact_id
    group_id="$(xmllint --xpath "string(${base}/*[local-name()='groupId'])" "${PARENT_POM}")"
    artifact_id="$(xmllint --xpath "string(${base}/*[local-name()='artifactId'])" "${PARENT_POM}")"
    if [ -z "${group_id}" ] || [ -z "${artifact_id}" ]; then
      continue
    fi
    cat >> "${TMP_OUTPUT}" <<EOF
            <plugin>
                <groupId>${group_id}</groupId>
                <artifactId>${artifact_id}</artifactId>
            </plugin>
EOF
  done
}

{
  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xmlns="http://maven.apache.org/POM/4.0.0"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.ndviet</groupId>
        <artifactId>test-parent-pom</artifactId>
        <version>${PARENT_REVISION}</version>
        <relativePath/>
    </parent>

    <artifactId>test-parent-pom-maven-cache-seed</artifactId>
    <name>Test Parent POM Maven Cache Seed</name>
    <version>${PARENT_REVISION}</version>
    <packaging>pom</packaging>

    <dependencies>
EOF
} > "${TMP_OUTPUT}"

append_dependencies_from_xpath "/*[local-name()='project']/*[local-name()='dependencyManagement']/*[local-name()='dependencies']/*[local-name()='dependency']" "false"
append_dependencies_from_xpath "/*[local-name()='project']/*[local-name()='dependencies']/*[local-name()='dependency']" "true"

cat >> "${TMP_OUTPUT}" <<'EOF'
    </dependencies>

    <build>
        <plugins>
EOF

append_plugins_from_xpath "/*[local-name()='project']/*[local-name()='build']/*[local-name()='pluginManagement']/*[local-name()='plugins']/*[local-name()='plugin']"

cat >> "${TMP_OUTPUT}" <<'EOF'
        </plugins>
    </build>
</project>
EOF

if [ -f "${SEED_POM}" ] && cmp -s "${TMP_OUTPUT}" "${SEED_POM}"; then
  echo "[java-base] Maven seed POM already up-to-date"
  exit 0
fi

mv "${TMP_OUTPUT}" "${SEED_POM}"
echo "[java-base] Updated ${SEED_POM} from ${PARENT_POM}"
