FROM gradle:jdk21 AS m2-seed-builder

USER root

WORKDIR /opt/bootstrap
COPY build.gradle /opt/bootstrap/test-parent-pom/build.gradle
COPY settings.gradle /opt/bootstrap/test-parent-pom/settings.gradle
COPY pom.xml /opt/bootstrap/test-parent-pom/pom.xml

RUN gradle --no-daemon -p /opt/bootstrap/test-parent-pom publishToMavenLocal

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

COPY --from=m2-seed-builder /root/.m2/repository /opt/m2-seed/repository

ENV GRADLE_USER_HOME=/root/.gradle
ENV WORKSPACE_DIR=/workspace

WORKDIR /workspace
COPY containers/java-base/entrypoint.sh /usr/local/bin/test-parent-pom-base-entrypoint.sh
RUN chmod +x /usr/local/bin/test-parent-pom-base-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/test-parent-pom-base-entrypoint.sh"]
CMD ["bash"]
