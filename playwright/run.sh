#!/usr/bin/with-contenv bashio
FILE="/config/playwright_ha.py"

if [ -f "$FILE" ]; then
    #cp -f /app/default.conf /etc/nginx/http.d/
    echo "File $FILE exists and is a regular file."
    chmod 777 /config/playwright_ha.py
    exec python3 /config/playwright_ha.py
else
    echo "File $FILE does not exist or is not a regular file."
fi


