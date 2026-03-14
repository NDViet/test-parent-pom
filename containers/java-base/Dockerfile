FROM maven:3.9.11-eclipse-temurin-17 AS maven-cache-builder

WORKDIR /opt/bootstrap
COPY pom.xml /opt/bootstrap/test-parent-pom/pom.xml
COPY containers/java-base/maven-seed/pom.xml /opt/bootstrap/maven-seed/pom.xml

RUN mvn -B -f /opt/bootstrap/test-parent-pom/pom.xml -DskipTests install \
    && mvn -B -f /opt/bootstrap/maven-seed/pom.xml -DskipTests -DincludeScope=test dependency:go-offline

FROM maven:3.9.11-eclipse-temurin-17

ARG GRADLE_VERSION=8.7

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       curl \
       git \
       procps \
       unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip \
    && mkdir -p /opt/gradle \
    && unzip -q /tmp/gradle.zip -d /opt/gradle \
    && mv "/opt/gradle/gradle-${GRADLE_VERSION}" /opt/gradle/current \
    && rm -f /tmp/gradle.zip

COPY --from=maven-cache-builder /root/.m2/repository /opt/m2-seed/repository

ENV GRADLE_HOME=/opt/gradle/current
ENV PATH="${GRADLE_HOME}/bin:${PATH}"
ENV GRADLE_USER_HOME=/root/.gradle
ENV WORKSPACE_DIR=/workspace

WORKDIR /workspace
COPY containers/java-base/entrypoint.sh /usr/local/bin/test-parent-pom-base-entrypoint.sh
RUN chmod +x /usr/local/bin/test-parent-pom-base-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/test-parent-pom-base-entrypoint.sh"]
CMD ["bash"]
