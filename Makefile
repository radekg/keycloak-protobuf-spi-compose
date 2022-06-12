ACME_DOMAIN?=idp-dev.gruchalski.com
ACME_EMAIL?=radek@gruchalski.com
CURRENT_DIR=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: certificates
certificates:
	docker run --rm \
		-v $(CURRENT_DIR)/etc/envoy:/lego \
		-v ${HOME}/.aws/credentials:/root/.aws/credentials \
		-e AWS_PROFILE=lego \
		-ti goacme/lego \
		--accept-tos \
		--domains=$(ACME_DOMAIN) \
		--server=https://acme-v02.api.letsencrypt.org/directory \
		--email=$(ACME_EMAIL) \
		--path=/lego \
		--dns=route53 run

.PHONY: docker.image.keycloak
docker.image.keycloak:
	docker build -t local/keycloak:18.0.0 "$(CURRENT_DIR)/.docker/keycloak/"

.PHONY: init-ca
init-ca:
	cd ${CURRENT_DIR}ca/ && certstrap init \
		--passphrase "" \
		--key-bits 4096 \
		--organization dev \
		--organizational-unit rnd \
		--country DE \
		--common-name $(ACME_DOMAIN).internal \
		--locality "GitHub and co"

.PHONY: cert-event-server
cert-event-server:
	cd ${CURRENT_DIR}ca/ \
		&& rm -rf keycloak-protobuf-event-server/* \
		&& certstrap request-cert \
			--passphrase "" \
			--common-name keycloak-protobuf-event-server \
			--domain keycloak-protobuf-event-server \
		&& certstrap sign keycloak-protobuf-event-server --CA $(ACME_DOMAIN).internal \
		&& mv out/keycloak-protobuf-event-server* keycloak-protobuf-event-server/ \
		&& chmod 0400 keycloak-protobuf-event-server/*

.PHONY: cert-event-client
cert-event-client:
	cd ${CURRENT_DIR}ca/ \
		&& rm -rf keycloak-protobuf-event-client/* \
		&& certstrap request-cert \
			--passphrase "" \
			--common-name keycloak-protobuf-event-client \
		&& certstrap sign keycloak-protobuf-event-client --CA $(ACME_DOMAIN).internal \
		&& mv out/keycloak-protobuf-event-client* keycloak-protobuf-event-client/ \
		&& chmod 0400 keycloak-protobuf-event-client/*
