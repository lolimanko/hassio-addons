ARG BUILD_FROM=ghcr.io/home-assistant/base-ubuntu:26.04
#ARG BUILD_FROM=ghcr.io/hassio-addons/ubuntu-base:11.0.0

ARG BUILD_FROM_KOMGA=ghcr.io/gotson/komga

FROM ${BUILD_FROM_KOMGA} AS komga

FROM ${BUILD_FROM}

COPY --from=komga /opt/java/openjdk /opt/java/openjdk
COPY --from=komga /app /app
COPY --from=komga /usr/bin/kepubify /usr/bin/kepubify

ENV JAVA_HOME="/opt/java/openjdk"
ENV PATH="/opt/java/openjdk/bin:${PATH}"

ENV \
    KOMGA_CONFIGDIR="/config" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"
    
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8
ENV LC_ALL=C.UTF-8
VOLUME /config
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*

COPY rootfs /
WORKDIR /
ENTRYPOINT ["/init"]

EXPOSE 25600