ARG BUILD_FROM=ghcr.io/hassio-addons/base:21.0.0
# hadolint ignore=DL3006
FROM ${BUILD_FROM}
ARG TARGETARCH

RUN apk add --no-cache openssl
RUN \
  apk --no-cache add \
    nginx \
  \
  && mkdir -p /run/nginx
RUN apk update && apk add --no-cache ffmpeg

COPY rootfs /
COPY stash-linux-${TARGETARCH} /usr/bin/stash
RUN chmod a+x  /usr/bin/stash
WORKDIR /
#CMD ["stash"]
#CMD ["/init"]
ENTRYPOINT ["/init"]
