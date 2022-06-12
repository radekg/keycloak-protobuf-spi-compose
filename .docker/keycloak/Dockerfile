FROM maven:3.3-jdk-8 as mvn
RUN mkdir -p /tmp/keycloak-protobuf-spi \
    && cd /tmp/keycloak-protobuf-spi \
    && git clone https://github.com/radekg/keycloak-protobuf-spi.git . \
    && NO_PROTOC_RUN=true mvn -Duser.home=/tmp/keycloak-protobuf-spi clean package \
    && export BUILD_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout) \
    && cp -v spi-provider-event-listener/target/keycloak-protobuf-spi-provider-event-listener-${BUILD_VERSION}-jar-with-dependencies.jar /tmp/keycloak-protobuf-spi-provider-event-listener-full.jar

FROM quay.io/keycloak/keycloak:18.0.0 as keycloak
COPY --from=mvn /tmp/keycloak-protobuf-spi-provider-event-listener-full.jar /opt/keycloak/providers/keycloak-protobuf-spi-provider-event-listener-full.jar
ENV KC_METRICS_ENABLED=true
ENV KC_FEATURES=token-exchange
ENV KC_DB=postgres
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:18.0.0
COPY --from=keycloak /opt/keycloak/providers/keycloak-protobuf-spi-provider-event-listener-full.jar /opt/keycloak/providers/keycloak-protobuf-spi-provider-event-listener-full.jar
COPY --from=keycloak /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
WORKDIR /opt/keycloak
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin
# Change these values to point to a running postgres instance.
ENV KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak?ssl=allow
ENV KC_DB_USERNAME=keycloak
ENV KC_DB_PASSWORD=keycloak
ENV KC_HOSTNAME=idp-dev.gruchalski.com
ENV KC_HOSTNAME_STRICT=false
ENV KC_HTTP_ENABLED=true
# This Keycloak's TLS is terminated on Envoy proxy, the setting below is required in this case.
ENV KC_PROXY=edge
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start"]
