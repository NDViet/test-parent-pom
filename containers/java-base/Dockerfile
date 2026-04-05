FROM gradle:jdk21 AS maven-cache-builder

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       maven \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/bootstrap
COPY build.gradle /opt/bootstrap/test-parent-pom/build.gradle
COPY settings.gradle /opt/bootstrap/test-parent-pom/settings.gradle
COPY pom.xml /opt/bootstrap/test-parent-pom/pom.xml
COPY containers/java-base/maven-seed/pom.xml /opt/bootstrap/maven-seed/pom.xml

RUN gradle --no-daemon -p /opt/bootstrap/test-parent-pom publishToMavenLocal \
    && mvn -B -f /opt/bootstrap/maven-seed/pom.xml -DskipTests -DincludeScope=test dependency:go-offline

FROM gradle:jdk21

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       curl \
       git \
       maven \
       procps \
       unzip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=maven-cache-builder /root/.m2/repository /opt/m2-seed/repository

ENV GRADLE_USER_HOME=/root/.gradle
ENV WORKSPACE_DIR=/workspace

WORKDIR /workspace
COPY containers/java-base/entrypoint.sh /usr/local/bin/test-parent-pom-base-entrypoint.sh
RUN chmod +x /usr/local/bin/test-parent-pom-base-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/test-parent-pom-base-entrypoint.sh"]
CMD ["bash"]
