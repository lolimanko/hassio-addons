#ARG BUILD_FROM=stashapp/stash:latest
ARG BUILD_FROM=ghcr.io/hassio-addons/base:21.0.0
# hadolint ignore=DL3006
FROM ${BUILD_FROM}
ARG TARGETARCH
#WORKDIR /root/.stash
#ADD . /
# Set environment variables
#RUN apt-get update && apt-get install -y
#RUN apt install ffmpeg -y
RUN apk add --no-cache openssl
RUN \
  apk --no-cache add \
    nginx \
  \
  && mkdir -p /run/nginx
RUN apk update && apk add --no-cache ffmpeg
#COPY stash-linux-arm64v8 /
COPY config.yml /config.yml
COPY nginx.conf /etc/nginx/nginx.conf
COPY mime.types /etc/nginx/includes/mime.types
COPY ingress.conf /etc/nginx/http.d/ingress.conf
COPY ssl.conf /ssl.conf
COPY proxy_params.conf /etc/nginx/includes/proxy_params.conf
COPY server_params.conf /etc/nginx/includes/server_params.conf
COPY stash-linux-${TARGETARCH} /usr/bin/stash
COPY run.sh /
RUN chmod a+x /run.sh
RUN chmod 777 -R /etc/nginx
RUN chmod 777  /usr/bin/stash
CMD [ "/run.sh" ]
#CMD ["stash"]

#ENTRYPOINT [ "stash-linux-arm64v8" ]


#CMD ["python3", "playwright_checkin.py"]