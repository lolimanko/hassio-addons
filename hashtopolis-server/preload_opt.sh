#!/bin/bash
chown -R www-data:www-data   ${HASHTOPOLIS_PATH}  && chmod -R g+w  ${HASHTOPOLIS_PATH} 
ssl=$(jq -r '.SSL' /data/options.json)

if [ "$ssl" = "true" ]; then
    a2enmod ssl && a2ensite default-ssl
fi
export HASHTOPOLIS_DB_TYPE=$(jq -r '.hashtopolis_db_type' /data/options.json)
export HASHTOPOLIS_DB_USER=$(jq -r '.hashtopolis_db_user' /data/options.json)
export HASHTOPOLIS_DB_PASS=$(jq -r '.hashtopolis_db_pass' /data/options.json)
export HASHTOPOLIS_DB_HOST=$(jq -r '.hashtopolis_db_host' /data/options.json)
export HASHTOPOLIS_DB_PORT=$(jq -r '.hashtopolis_db_port' /data/options.json)
export HASHTOPOLIS_DB_DATABASE=$(jq -r '.hashtopolis_db_database' /data/options.json)
export HASHTOPOLIS_ADMIN_USER=$(jq -r '.hashtopolis_admin_user' /data/options.json)
export HASHTOPOLIS_ADMIN_PASSWORD=$(jq -r '.hashtopolis_admin_password' /data/options.json)
export HASHTOPOLIS_BACKEND_URL=$(jq -r '.hashtopolis_backend_url' /data/options.json)
export HASHTOPOLIS_FRONTEND_URLS=$(jq -r '.hashtopolis_frontend_urls' /data/options.json)

gosu www-data /usr/local/bin/docker-entrypoint.sh
docker-php-entrypoint apache2-foreground