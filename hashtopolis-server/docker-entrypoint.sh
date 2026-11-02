#!/usr/bin/env bashio

#chown -R www-data:www-data /usr/local/share/hashtopolis
#chmod -R u+rwX /usr/local/share/hashtopolis
#source /usr/lib/bashio/bashio.sh
ssl=$(bashio::config 'SSL')
if [ "$ssl" = "true" ]; then
    a2enmod ssl && a2ensite default-ssl
fi
#exec su -s /bin/bash www-data -c 'exec "$0" "$@"' "$0" "$@"

export HASHTOPOLIS_DB_TYPE=$(bashio::config 'hashtopolis_db_type')
export HASHTOPOLIS_DB_USER=$(bashio::config 'hashtopolis_db_user')
export HASHTOPOLIS_DB_PASS=$(bashio::config 'hashtopolis_db_pass')
export HASHTOPOLIS_DB_HOST=$(bashio::config 'hashtopolis_db_host')
export HASHTOPOLIS_DB_PORT=$(bashio::config 'hashtopolis_db_port')
export HASHTOPOLIS_DB_DATABASE=$(bashio::config 'hashtopolis_db_database')
export HASHTOPOLIS_ADMIN_USER=$(bashio::config 'hashtopolis_admin_user')
export HASHTOPOLIS_ADMIN_PASSWORD=$(bashio::config 'hashtopolis_admin_password')
export HASHTOPOLIS_BACKEND_URL=$(bashio::config 'hashtopolis_backend_url')
export HASHTOPOLIS_FRONTEND_URLS=$(bashio::config 'hashtopolis_frontend_urls')

runuser -u www-data --preserve-environment -- /bin/bash /usr/local/bin/hashtopolis-init.sh
