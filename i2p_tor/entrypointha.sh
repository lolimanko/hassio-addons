#!/usr/bin/env bashio
#
export IP_HOST=$(bashio::config 'IP_HOST')
export PORT_TOR=$(bashio::config 'PORT_TOR')
export PORT_HTTP_PROXY=$(bashio::config 'PORT_HTTP_PROXY')
#export ENABLE_HTTPPROXY=$(bashio::config 'ENABLE_HTTPPROXY')
#export ENABLE_SOCKSPROXY=$(bashio::config 'ENABLE_SOCKSPROXY')
export ENABLE_HTTPPROXY=$([[ "$(bashio::config 'ENABLE_HTTPPROXY')" == "true" ]] && echo 1 || echo 0)
export ENABLE_SOCKSPROXY=$([[ "$(bashio::config 'ENABLE_SOCKSPROXY')" == "true" ]] && echo 1 || echo 0)

runuser -u root --preserve-environment -- /bin/bash /entrypoint.sh
