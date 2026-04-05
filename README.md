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

## Gradle build, deploy, and release

`pom.xml` remains the source of truth for the parent POM metadata. Gradle now drives this repository's build and publishing flow by rendering a resolved POM from that template.

Build and verify the generated parent POM:

```shell
gradle build
```

Format Java sources:

```shell
gradle formatJava
```

Install the parent POM to your local Maven cache:

```shell
gradle publishToMavenLocal
```

Deploy a snapshot or release revision to GitHub Packages:

```shell
GH_PACKAGES_USERNAME=...
GH_PACKAGES_TOKEN=...
GITHUB_REPOSITORY=ndviet/test-parent-pom
gradle deploy -Prevision=26.3.0-SNAPSHOT
```

Publish a non-SNAPSHOT release:

```shell
GH_PACKAGES_USERNAME=...
GH_PACKAGES_TOKEN=...
GITHUB_REPOSITORY=ndviet/test-parent-pom
gradle release -Prevision=26.3.0
```

## Java base image (for downstream repos)

This repository provides a standalone base image: `test-automation-java-base`.

It contains:

- Java 21
- Maven
- Gradle CLI
- Official base image: `gradle:jdk21`
- Pre-seeded Maven local repository with the published `test-parent-pom` artifact
- Offline-first execution defaults (`mvn -o`, `gradle --offline`) to prevent network fetch in downstream runs

Build locally:

```shell
./containers/build-java-base-image.sh ghcr.io/ndviet/test-automation-java-base
```

Tags created:

- `ghcr.io/ndviet/test-automation-java-base:latest`
- `ghcr.io/ndviet/test-automation-java-base:<revision>` (from `<revision>` in `pom.xml`)

GitHub Actions workflow:

- `.github/workflows/publish-java-base-image.yml`
- `.github/workflows/publish-maven-github.yml`

Workflow tagging behavior:

- `push` on `master`: publishes `ghcr.io/ndviet/test-automation-java-base:<revision>-SNAPSHOT`
- `push` on tag `v*`: publishes release tags
  - `ghcr.io/ndviet/test-automation-java-base:latest`
  - `ghcr.io/ndviet/test-automation-java-base:<revision-without-SNAPSHOT>`

Required repository secrets for publish:

- `GH_PACKAGES_USERNAME`
- `GH_PACKAGES_TOKEN`

Optional runtime override (if online fetch is intentionally needed):

- `FORCE_MAVEN_OFFLINE=false`
- `FORCE_GRADLE_OFFLINE=false`
