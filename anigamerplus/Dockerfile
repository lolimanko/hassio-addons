FROM python:3.9-slim

RUN apt update && \
    apt install -y g++ gcc make libevent-dev libffi-dev libxml2-dev libxslt-dev zlib1g-dev ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN pip3 install --no-cache-dir -r requirements.txt

ENTRYPOINT [ "python3", "-u", "aniGamerPlus.py" ]
