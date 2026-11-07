#!/usr/bin/env bashio
export HASHTOPOLIS_BACKEND_URL=$(bashio::config 'hashtopolis_backend_url')
ssl=$(bashio::config 'SSL')
if [  "$ssl" = "false"   ]; then
  echo "ssl false"
  rm /etc/nginx/conf.d/ssl.conf
fi
/usr/local/bin/docker-entrypoint.sh
