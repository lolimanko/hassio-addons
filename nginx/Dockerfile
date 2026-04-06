ARG BUILD_FROM=ghcr.io/hassio-addons/base:20.0.1
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