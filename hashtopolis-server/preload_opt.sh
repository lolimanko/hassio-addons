#!/usr/bin/env bashio
ssl=$(bashio::config 'SSL')
if [ "$ssl" = "true" ]; then
    
    a2enmod ssl && a2ensite default-ssl

fi

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
/usr/local/bin/docker-entrypoint.sh production
