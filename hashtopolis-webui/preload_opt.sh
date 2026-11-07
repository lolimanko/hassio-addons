#!/usr/bin/env bashio
export HASHTOPOLIS_BACKEND_URL=$(bashio::config 'hashtopolis_backend_url')
export ssl=$(bashio::config 'SSL')
/usr/local/bin/docker-entrypoint.sh production
