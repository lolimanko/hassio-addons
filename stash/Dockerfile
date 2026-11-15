ARG BUILD_FROM=ghcr.io/hassio-addons/base:21.0.0
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

ARG STASH_VERSION=v0.32.0


RUN apk add --no-cache \
      libcrypto3 \
      libssl3 \
      nginx \
      ffmpeg \
      wget \
      openssl \
    && mkdir -p /run/nginx

# 依架構下載對應的 Stash 執行檔
RUN set -eux; \
    case "$(uname -m)" in \
      x86_64)  ASSET="stash-linux" ;; \
      aarch64) ASSET="stash-linux-arm64v8" ;; \
      *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    wget -q -O /usr/bin/stash \
      "https://github.com/stashapp/stash/releases/download/${STASH_VERSION}/${ASSET}"; \
    chmod a+x /usr/bin/stash

# rootfs 放在最後,改 nginx 設定或 run script 時不會重跑下載
COPY rootfs /

WORKDIR /
ENTRYPOINT ["/init"]
