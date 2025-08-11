#!/usr/bin/with-contenv bashio
user_name=$(bashio::config 'user_name')
user_phone=$(bashio::config 'user_phone')
user_number=$(bashio::config 'user_number')
camera_ip=$(bashio::config 'camera_ip')
exec python3 playwright_gas.py $user_number $user_name $user_phone $camera_ip