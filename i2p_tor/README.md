Open your favourite browser, like Firefox. Open the settings. Search for "proxy". Then enable "Automatic proxy configuration URL" and set it to "http://localhost:8082/proxy.pac".

REMARK: if your docker container is running on a network server (example: a NAS or a Raspberry PI) replace "localhost" by the IP address of your network server. Example: http://10.11.12.13:8082/proxy.pac

This proxy configuration (see source code below for details) uses your new docker container to route all your browser traffic through either I2P or Tor. If you now browse the clearnet (like https://diva.exchange) you'll be using automatically Tor.

If you prefer a weaker configuration you can also use the proxy file proxy-ip2-onion-clearnet.pac and set the "Automatic proxy configuration URL" to "http://localhost:8082/proxy-ip2-onion-clearnet.pac". This will only route .i2p and .onion addresses through the docker container. Routes to the clearnet won't be affected.
