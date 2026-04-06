#!/usr/bin/with-contenv bashio
FILE="/config/default.conf"

if [ -f "$FILE" ]; then
    cp -f /config/default.conf /etc/nginx/http.d/
    echo "File $FILE exists and is a regular file."
else
    echo "File $FILE does not exist or is not a regular file."
fi
nginx -g "daemon off;error_log /dev/stdout debug;"