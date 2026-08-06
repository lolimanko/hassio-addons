#!/usr/bin/with-contenv bashio

#INGRESS_PATH="$(bashio::app.ingress_entry)"
ssl=$(bashio::config 'ssl')

certfile=$(bashio::config 'certfile')

keyfile=$(bashio::config 'keyfile')
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
INGRESS_PATH="$(bashio::addon.ingress_entry)"
#SERVER_SERVLET_CONTEXT_PATH=$(bashio::addon.ingress_entry)
sed -i "s/%%port%%/$ingress_port/g" /etc/nginx/http.d/ingress.conf
sed -i "s/%%interface%%/$ingress_interface/g" /etc/nginx/http.d/ingress.conf
if [ $ssl ]; then
    echo "ssl enable."
    cp /ssl.conf /etc/nginx/http.d/ssl.conf
    sed -i "s/%%certfile%%/${certfile}/g" /etc/nginx/http.d/ssl.conf
    sed -i "s/%%keyfile%%/${keyfile}/g" /etc/nginx/http.d/ssl.conf
else
    echo "ssl disable."
    #cp /config.yml /root/.stash/config.yml
fi
nginx -g "daemon off;error_log /dev/stdout debug;" & java -Dspring.profiles.include=docker --enable-native-access=ALL-UNNAMED -jar application.jar --spring.config.additional-location=file:/config/

#ENTRYPOINT ["java", "-Dspring.profiles.include=docker", "--enable-native-access=ALL-UNNAMED", "-jar", "application.jar", "--spring.config.additional-location=file:/config/"]
#EXPOSE 25600
