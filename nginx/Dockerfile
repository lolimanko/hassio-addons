ARG BUILD_FROM
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