ARG BUILD_FROM=stashapp/stash:latest
# hadolint ignore=DL3006
FROM ${BUILD_FROM}


RUN apk add --no-cache openssl

COPY config.yml /config.yml

COPY run.sh /run.sh
RUN chmod +x /run.sh
ENTRYPOINT ["/run.sh"]
