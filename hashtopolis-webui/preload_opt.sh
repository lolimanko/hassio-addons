#!/bin/bash
#export HASHTOPOLIS_BACKEND_URL=$(bashio::config 'hashtopolis_backend_url')
export HASHTOPOLIS_BACKEND_URL=$(jq -r '.hashtopolis_backend_url' /data/options.json)
#ssl=$(bashio::config 'SSL')
ssl=$(jq -r '.SSL' /data/options.json)
if [  "$ssl" = "false"   ]; then
  echo "ssl false"
  rm /etc/nginx/conf.d/ssl.conf
fi
/usr/local/bin/docker-entrypoint.sh production
