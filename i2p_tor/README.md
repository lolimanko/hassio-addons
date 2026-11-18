Open your favourite browser, like Firefox. Open the settings. Search for "proxy". Then enable "Automatic proxy configuration URL" and set it to "http://homeassistant.local:8082/proxy.pac".

This proxy configuration (see source code below for details) uses your new docker container to route all your browser traffic through either I2P or Tor. If you now browse the clearnet (like https://diva.exchange) you'll be using automatically Tor.

If you prefer a weaker configuration you can also use the proxy file proxy-ip2-onion-clearnet.pac and set the "Automatic proxy configuration URL" to "http://homeassistant.local:8082/proxy-ip2-onion-clearnet.pac". This will only route .i2p and .onion addresses through the docker container. Routes to the clearnet won't be affected.
