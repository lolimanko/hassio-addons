ARG BUILD_FROM
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

#WORKDIR /
#ADD . /
# Set environment variables


#RUN apk update


ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
# Install system dependencies
#RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/pytho
RUN apt-get update && apt-get install -y
RUN apt install python3-full -y
RUN apt install python3-pip -y
#RUN python3 -m ensurepip --default-pip
#RUN pip3 install --no-cache --upgrade pip setuptools
#RUN pip install pytest-playwright
#RUN apt instal playwright
RUN pip install playwright
#RUN pip install --upgrade pip
#UN pip install selenium
# Install Playwright browsers and dependencies
RUN playwright install --with-deps chromium
RUN pip install APScheduler
RUN pip install requests
RUN pip install psycopg2-binary
# Command to run the Playwright test script
COPY run.sh /
COPY playwright_checkin.py /
#COPY index.html /
RUN chmod a+x /run.sh
RUN chmod a+x /playwright_checkin.py
#RUN chmod a+x /index.html
CMD [ "/run.sh" ]

#CMD ["run.sh"]

#CMD ["python3", "playwright_checkin.py"]