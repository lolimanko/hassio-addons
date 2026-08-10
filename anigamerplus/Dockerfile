ARG BUILD_FROM=ghcr.io/home-assistant/base-python:3.12-alpine3.24
# hadolint ignore=DL3006
FROM ${BUILD_FROM}


RUN apk add --no-cache \
    gcc \
    g++ \
    make \
    musl-dev \
    libevent-dev \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    zlib-dev \
    ffmpeg \
    curl-dev \
    openssl-dev \
    cargo \
    linux-headers



COPY rootfs /
WORKDIR /
RUN pip install --no-cache-dir -r requirements.txt


ENTRYPOINT ["/init"]


