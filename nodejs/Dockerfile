#ARG BUILD_FROM
# hadolint ignore=DL3006
#FROM ${BUILD_FROM}
FROM node:24-alpine

#WORKDIR /
#ADD . /
# Set environment variables
#RUN apt-get update && apt-get install -y
#RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
#RUN \. "$HOME/.nvm/nvm.sh"

#RUN nvm install 24

#COPY a /
#COPY run.sh /

#RUN chmod a+x /run.sh
#RUN chmod u+x /media/vue
#WORKDIR /media/vue-supervise
WORKDIR /media/vue-project
#WORKDIR /media/vue
#CMD [ "/run.sh" ]
#CMD [ "npm","remove" ]
#CMD [ "npm","install" ]
#CMD [ "npm","run","dev" ]
CMD [ "npm","run","build" ]

#CMD ["python3", "playwright_checkin.py"]