## Introduction

This is a parent POM that is shared across my GitHub repositories.<br>
This is used to centralize versions, plugin setup and common properties to avoid redundancies or duplicate
configurations using inheritance between pom files. It helps in easy maintenance in long term.

## Dependent repositories

1. [test-automation-fwk](../../../test-automation-fwk)
2. [test-java2robot-adapter](../../../test-java2robot-adapter)
3. [test-webdriver-downloader](../../../test-webdriver-downloader)
4. [test-robot-framework](../../../test-robot-framework)
5. [test-testng-framework](../../../test-testng-framework)
6. [test-cucumber-framework](../../../test-cucumber-framework)

## Usage

In the same directory, clone this repository first and after that clone other dependent repositories.

```shell
git clone git@github.com:ndviet/test-parent-pom.git
```

## Java base image (for downstream repos)

This repository provides a standalone base image: `test-automation-java-base`.

It contains:

- Java 17
- Maven
- Gradle CLI
- Pre-seeded Maven local repository based on this parent POM dependency/plugin management
- Offline-first execution defaults (`mvn -o`, `gradle --offline`) to prevent network fetch in downstream runs

Build locally:

```shell
./containers/build-java-base-image.sh ndviet/test-automation-java-base
```

`containers/java-base/maven-seed/pom.xml` is generated from `pom.xml` by:

```shell
./containers/java-base/sync-maven-seed.sh
```

Do not update the seed POM manually.

Tags created:

- `ndviet/test-automation-java-base:latest`
- `ndviet/test-automation-java-base:<revision>` (from `<revision>` in `pom.xml`)

GitHub Actions workflow:

- `.github/workflows/publish-java-base-image.yml`

Workflow tagging behavior:

- `push` on `master`: publishes `ndviet/test-automation-java-base:<revision>-SNAPSHOT`
- `push` on tag `v*`: publishes release tags
  - `ndviet/test-automation-java-base:latest`
  - `ndviet/test-automation-java-base:<revision-without-SNAPSHOT>`

Required repository secrets for publish:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

Optional runtime override (if online fetch is intentionally needed):

- `FORCE_MAVEN_OFFLINE=false`
- `FORCE_GRADLE_OFFLINE=false`
