FROM eclipse-temurin:21-jre-resolute AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \    
    wget \
    curl \
    ca-certificates \
    unzip \
    expect \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

ARG HYPHANET_VERSION=1507
ENV HYPHANET_INSTALLER_URL=https://www.draketo.de/dateien/freenet/build0${HYPHANET_VERSION}/new_installer_offline_${HYPHANET_VERSION}.jar
ENV INSTALLER_JAR=new_installer_offline.jar
ENV HYPHANET_HOME=/opt/hyphanet
ENV INSTALL_USER=installer
ENV INSTALL_UID=1001
ENV INSTALL_GID=1001

RUN groupadd --gid ${INSTALL_GID} ${INSTALL_USER} && \
    useradd --uid ${INSTALL_UID} --gid ${INSTALL_GID} --shell /bin/bash --create-home ${INSTALL_USER}

RUN mkdir -p ${HYPHANET_HOME} && chown ${INSTALL_UID}:${INSTALL_GID} ${HYPHANET_HOME}

#RUN chmod 777 -R ${HYPHANET_HOME}
#RUN chmod 777 -R /data
USER ${INSTALL_USER}
WORKDIR /home/${INSTALL_USER}

# Test DNS resolution and try multiple download methods
RUN echo "Testing DNS resolution..." && \
    nslookup www.draketo.de || echo "nslookup failed, trying with dig..." && \
    dig www.draketo.de || echo "dig failed, continuing..." && \
    echo "Attempting download with wget..." && \
    (wget --progress=bar:force:noscroll --tries=3 --timeout=30 --dns-timeout=10 -O ${INSTALLER_JAR} "${HYPHANET_INSTALLER_URL}" || \
     echo "wget failed, trying with curl..." && \
     curl -L --connect-timeout 30 --max-time 300 --retry 3 -o ${INSTALLER_JAR} "${HYPHANET_INSTALLER_URL}")

COPY --chmod=755 <<'EOT' install_script.exp
#!/usr/bin/expect -f
set hyphanet_home "/opt/hyphanet"
set installer_jar "new_installer_offline.jar"
set timeout 600

puts "DEBUG: HYPHANET_HOME in expect is $hyphanet_home"
puts "DEBUG: INSTALLER_JAR in expect is $installer_jar"
puts "Starting installation of Hyphanet"

if {![file exists $installer_jar]} {
    puts "ERROR: Installer JAR '$installer_jar' not found!"
    exit 1
}
spawn java -jar $installer_jar -console

expect "Select target path*"
send -- "$hyphanet_home\n"

expect "press 1 to continue, 2 to quit, 3 to redisplay"
send "1\n"

expect {
    "Console installation done" { puts "Installation appears successful (Console installation done)" }
    "All done" { puts "Installation appears successful (All done)" }
    timeout { puts "ERROR: Installation Timeout"; exit 1 }
    eof { puts "ERROR: Unexpected EOF during installation"; exit 1 }
}

expect eof
catch wait result
set exit_status [lindex $result 3]
if {$exit_status != 0} {
    puts "ERROR: Java installer process exited with status $exit_status"
    exit 1
}
puts "Expect script finished successfully."
EOT

RUN ./install_script.exp

RUN echo "DEBUG BUILD: Content of ${HYPHANET_HOME} after install:" && \
    ls -lRa ${HYPHANET_HOME} || echo "DEBUG BUILD: Failed to list ${HYPHANET_HOME}" && \
    echo "DEBUG BUILD: Searching for .sh files in ${HYPHANET_HOME}..." && \
    find ${HYPHANET_HOME} -type f -name "*.sh" 2>/dev/null | sort || echo "DEBUG BUILD: No .sh files found"


FROM eclipse-temurin:21-jre-resolute

ENV HYPHANET_USER=hyphanet
ENV HYPHANET_UID=1002
ENV HYPHANET_GID=1002
ENV HYPHANET_HOME=/opt/hyphanet
ENV HYPHANET_DATA=/config


RUN apt-get update && apt-get install -y --no-install-recommends \
    iproute2 \
    socat \
    nginx \
    jq \
    gosu \
    apache2-utils \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${HYPHANET_GID} ${HYPHANET_USER} && \
    useradd --uid ${HYPHANET_UID} --gid ${HYPHANET_GID} --shell /bin/bash --create-home ${HYPHANET_USER}

COPY --from=builder --chown=${HYPHANET_UID}:${HYPHANET_GID} ${HYPHANET_HOME} ${HYPHANET_HOME}

RUN mkdir -p ${HYPHANET_DATA} && \
  chown ${HYPHANET_UID}:${HYPHANET_GID} ${HYPHANET_DATA}
  
#RUN chmod 777 -R ${HYPHANET_DATA}


COPY nginx.conf /etc/nginx/nginx.conf

COPY --chown=${HYPHANET_UID}:${HYPHANET_GID} hyphanet.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/

#RUN chmod 777 /dev/stdout

RUN chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/hyphanet.sh
#RUN chmod 777 /etc/nginx/nginx.conf

#USER ${HYPHANET_USER}
#USER ROOT
WORKDIR ${HYPHANET_HOME}

EXPOSE 8888
VOLUME [ "${HYPHANET_DATA}" ]

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
#ENTRYPOINT [ "/usr/local/bin/ha.sh" ]
CMD [ "start" ]
