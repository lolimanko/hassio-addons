#!/usr/bin/with-contenv bashio

#INGRESS_PATH="$(bashio::app.ingress_entry)"
ssl=$(bashio::config 'ssl')

certfile=$(bashio::config 'certfile')

keyfile=$(bashio::config 'keyfile')
ingress_port=$(bashio::app.ingress_port)
ingress_interface=$(bashio::app.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/http.d/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/http.d/ingress.conf

if [ -f "/root/.stash/config.yml" ]; then
    
    echo "config.yml exist."

else
    echo "config.yml not exist."
    cp /config.yml /root/.stash/config.yml
fi
if [ $ssl ]; then
    
    echo "ssl enable."
    cp /ssl.conf /etc/nginx/http.d/ssl.conf
    sed -i "s/%%certfile%%/${certfile}/g" /etc/nginx/http.d/ssl.conf
    sed -i "s/%%keyfile%%/${keyfile}/g" /etc/nginx/http.d/ssl.conf
else
    echo "ssl disable."
    #cp /config.yml /root/.stash/config.yml
fi
#sed -i "s|external_host:|external_host: https://buvi.duckdns.org:8123$INGRESS_PATH|g" /root/.stash/config.yml
if grep -q 'jwt_secret_key' '/root/.stash/config.yml'; then
  echo "Found jwt_secret_key."
else
  echo "not Found jwt_secret_key."
  echo 'jwt_secret_key: '$(openssl rand -hex 32) >> '/root/.stash/config.yml'
  
fi
if grep -q 'session_store_key' '/root/.stash/config.yml'; then
  echo "Found session_store_key."
else
  echo "not Found session_store_key."
  echo 'session_store_key: '$(openssl rand -hex 32) >> '/root/.stash/config.yml'
  
fi
if [ -d /root/.stash/generated ]; then
  echo "generated Yes"
else
  echo "generated No"
  mkdir /root/.stash/generated
fi
if [ -d /root/.stash/cache ]; then
  echo "cache Yes"
else
  echo "cache No"
  mkdir /root/.stash/cache
fi
if [ -d /root/.stash/blobs ]; then
  echo "blobs Yes"
else
  echo "blobs No"
  mkdir /root/.stash/blobs
fi

nginx -g "daemon off;error_log /dev/stdout debug;" & exec stash


