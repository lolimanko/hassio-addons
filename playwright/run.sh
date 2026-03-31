#!/usr/bin/with-contenv bashio

FILE="/app/playwright_ha.py"

if [ -f "$FILE" ]; then
    echo "File $FILE exists and is a regular file."

    chmod 777 /app/playwright_ha.py

    exec python3 /app/playwright_ha.py
else
    echo "File $FILE does not exist or is not a regular file."
fi
#nginx -g "daemon off;error_log /dev/stdout debug;"

