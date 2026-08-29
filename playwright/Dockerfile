ARG BUILD_FROM=ghcr.io/home-assistant/base-ubuntu:24.04
FROM ${BUILD_FROM}

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-full \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Use an isolated virtual environment rather than installing packages
# into the system Python.
RUN python3 -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
        playwright \
        APScheduler \
        requests \
        psycopg2-binary \
    && playwright install --with-deps chromium

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]