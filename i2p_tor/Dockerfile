FROM divax/i2p:current-i2p-tor

ARG BASHIO_VERSION="v0.19.0"
RUN apk --no-cache add \
  bash \
  curl \
  jq runuser \
  && curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/${BASHIO_VERSION}.tar.gz" \
  && mkdir /tmp/bashio \
  && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio \
  && mv /tmp/bashio/lib /usr/lib/bashio \
  && ln -s /usr/lib/bashio/bashio /usr/bin/bashio
COPY entrypointha.sh /entrypointha.sh
RUN chmod +x /entrypointha.sh
ENTRYPOINT ["/entrypointha.sh"]
