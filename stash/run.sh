#!/bin/sh

if [ -f "/root/.stash/config.yml" ]; then
    
    echo "config.yml exist."

else
    echo "config.yml not exist."
    cp /config.yml /root/.stash/config.yml
fi

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
exec stash