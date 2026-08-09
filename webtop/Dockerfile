ARG BUILD_FROM=ghcr.io/alexbelgium/webtop-aarch64
FROM ${BUILD_FROM}

RUN apt update -y && apt install wine -y


CMD [ "/ha_entrypoint.sh" ]