ARG BUILD_FROM=ghcr.io/hassio-addons/base:21.0.0
FROM $BUILD_FROM

#Add nginx and create the run folder for nginx.
RUN \
  apk --no-cache add \
    nginx \
  \
  && mkdir -p /run/nginx


WORKDIR /

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]