ARG BUILD_FROM
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

WORKDIR /stash
#ADD . /
# Set environment variables
RUN apt-get update && apt-get install -y
RUN apt install ffmpeg -y

COPY stash-linux /
COPY run-amd64.sh /

RUN chmod a+x /run-amd64.sh
RUN chmod a+x /stash-linux

CMD [ "/run-amd64.sh" ]
