ARG BUILD_FROM=ghcr.io/home-assistant/base-ubuntu:26.04
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN apt-get update && apt-get install -y python3-full python3-venv

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip
RUN pip install playwright
RUN playwright install --with-deps chromium
RUN pip install APScheduler
RUN pip install requests
RUN pip install psycopg2-binary

COPY run.sh /
RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
