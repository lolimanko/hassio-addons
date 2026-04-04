#!/usr/bin/with-contenv bashio
cookie=$(bashio::config 'cookie')

cookie_overwrite=$(bashio::config 'cookie_overwrite')

ssl=$(bashio::config 'ssl')

certfile=$(bashio::config 'certfile')

keyfile=$(bashio::config 'keyfile')

if [ -f "configs/cookie.txt" ]; then
    
    echo "cookie exist."
    if [ $cookie_overwrite == true ]; then
        echo $cookie > 'configs/cookie.txt'
        echo "cookie overwrited  ."
    fi
else
    
    echo $cookie > 'configs/cookie.txt'
    echo "cookie create."
fi

exec python3 -u aniGamerPlus.py --bashio $ssl $certfile $keyfile