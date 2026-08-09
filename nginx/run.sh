#!/usr/bin/with-contenv bashio
DIR="/config/nginx"

if [ -d "$DIR" ]; then
    cp -r /config/nginx /etc
    echo "File $DIR exists and is a regular file."
else
    echo "File $DIR does not exist or is not a regular file."
fi
nginx -g "daemon off;error_log /dev/stdout debug;"