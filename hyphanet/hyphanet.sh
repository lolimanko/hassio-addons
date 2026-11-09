#!/bin/bash
set -e

# ==================================================
# 1. Environment
# ==================================================

HYPHANET_HOME="${HYPHANET_HOME:-/opt/hyphanet}"
HYPHANET_DATA="${HYPHANET_DATA:-/config}"

SOCAT_LISTEN_PORT=8123
HYPHANET_FPROXY_PORT=8888

CONFIG_INI="${HYPHANET_DATA}/freenet.ini"
WRAPPER_CONF="${HYPHANET_HOME}/wrapper.conf"
WRAPPER_LOG_PATH="${HYPHANET_DATA}/wrapper.log"

echo "========================================"
echo " Hyphanet Entrypoint"
echo "========================================"
echo "User:          $(whoami)"
echo "Home:          ${HYPHANET_HOME}"
echo "Data:          ${HYPHANET_DATA}"
echo "SOCAT Port:    ${SOCAT_LISTEN_PORT}"
echo "FProxy Port:   ${HYPHANET_FPROXY_PORT}"
echo "========================================"


# ==================================================
# 2. Prepare persistent storage
# ==================================================

echo "[1/6] Preparing persistent storage..."

mkdir -p "${HYPHANET_DATA}"

PERSISTENT_DIRS=(
    "downloads"
    "persistent-temp"
    "datastore/certs"
    "plugin-data"
    "temp"
    "plugins"
    "stats"
    "store"
    "freenet"
)

for item in "${PERSISTENT_DIRS[@]}"; do
    mkdir -p "${HYPHANET_DATA}/${item}"
done


# ==================================================
# 3. Initialize freenet.ini
# ==================================================

echo "[2/6] Checking freenet.ini..."

if [ ! -f "${CONFIG_INI}" ]; then

    if [ ! -f "${HYPHANET_HOME}/freenet.ini" ]; then
        echo "ERROR: Initial freenet.ini not found!"
        exit 1
    fi

    echo "Initializing freenet.ini..."

    cp -a "${HYPHANET_HOME}/freenet.ini" "${CONFIG_INI}"

    # Configure persistent paths
    sed -i \
        -e "s#^ssl\\.sslKeyStore=.*#ssl.sslKeyStore=${HYPHANET_DATA}/datastore/certs#" \
        -e "s#^node\\.downloadsDir=.*#node.downloadsDir=${HYPHANET_DATA}/downloads#" \
        -e "s#^node\\.install\\.persistentTempDir=.*#node.install.persistentTempDir=${HYPHANET_DATA}/persistent-temp#" \
        -e "s#^node\\.install\\.storeDir=.*#node.install.storeDir=${HYPHANET_DATA}/datastore#" \
        -e "s#^node\\.install\\.pluginStoresDir=.*#node.install.pluginStoresDir=${HYPHANET_DATA}/plugin-data#" \
        -e "s#^node\\.install\\.tempDir=.*#node.install.tempDir=${HYPHANET_DATA}/temp#" \
        -e "s#^node\\.install\\.pluginDir=.*#node.install.pluginDir=${HYPHANET_DATA}/plugins#" \
        "${CONFIG_INI}"

    echo "Initial configuration created."

else
    echo "Existing freenet.ini found. Keeping existing configuration."
fi


# ==================================================
# 4. Initialize other persistent files
# ==================================================

echo "[3/6] Preparing persistent files..."

PERSISTENT_FILES=(
    "freenet.ini.bak"
    "node.random"
    "master.keys"
    "seednodes.fref"
    "wrapper.log"
)

for item in "${PERSISTENT_FILES[@]}"; do

    src_path="${HYPHANET_HOME}/${item}"
    dest_path="${HYPHANET_DATA}/${item}"

    if [ ! -e "${dest_path}" ] && [ -f "${src_path}" ]; then
        echo "Copying ${item}..."
        cp -a "${src_path}" "${dest_path}"
    fi

done


# ==================================================
# 5. Configure Java Service Wrapper
# ==================================================

echo "[4/6] Configuring Wrapper..."

if [ ! -f "${WRAPPER_CONF}" ]; then
    echo "ERROR: wrapper.conf not found!"
    exit 1
fi

if grep -q '^wrapper.app.parameter.1=' "${WRAPPER_CONF}"; then

    sed -i \
        "s#^wrapper.app.parameter.1=.*#wrapper.app.parameter.1=${CONFIG_INI}#" \
        "${WRAPPER_CONF}"

else
    echo "ERROR: wrapper.app.parameter.1 not found!"
    exit 1
fi

echo "Wrapper configuration:"
grep '^wrapper.app.parameter.1=' "${WRAPPER_CONF}"


# ==================================================
# 6. Start Hyphanet
# ==================================================

if [ "$1" = "start" ]; then

    echo "[5/6] Configuring FProxy..."

    sed -i -E \
        's#^fproxy\.bindTo[[:space:]]*=.*#fproxy.bindTo=0.0.0.0#' \
        "${CONFIG_INI}"

    sed -i -E \
        's#^fproxy\.allowedHosts[[:space:]]*=.*#fproxy.allowedHosts=*#' \
        "${CONFIG_INI}"

    sed -i -E \
        's#^fproxy\.allowedHostsFullAccess[[:space:]]*=.*#fproxy.allowedHostsFullAccess=*#' \
        "${CONFIG_INI}"

    grep -q '^fproxy.enabled=' "${CONFIG_INI}" || \
        echo "fproxy.enabled=true" >> "${CONFIG_INI}"

    grep -q '^fproxy.port=' "${CONFIG_INI}" || \
        echo "fproxy.port=${HYPHANET_FPROXY_PORT}" >> "${CONFIG_INI}"

    grep -q '^fproxy.bindTo=' "${CONFIG_INI}" || \
        echo "fproxy.bindTo=0.0.0.0" >> "${CONFIG_INI}"

    grep -q '^fproxy.allowedHosts=' "${CONFIG_INI}" || \
        echo "fproxy.allowedHosts=*" >> "${CONFIG_INI}"

    grep -q '^fproxy.allowedHostsFullAccess=' "${CONFIG_INI}" || \
        echo "fproxy.allowedHostsFullAccess=*" >> "${CONFIG_INI}"

    echo "FProxy configuration:"
    grep '^fproxy\.' "${CONFIG_INI}" || true


    # ----------------------------------------------
    # Find run.sh
    # ----------------------------------------------

    echo "[6/6] Searching for Hyphanet start script..."

    potential_scripts=(
        "${HYPHANET_HOME}/run.sh"
        "${HYPHANET_HOME}/Hyphanet/run.sh"
        "${HYPHANET_HOME}/Freenet/run.sh"
        "${HYPHANET_HOME}/freenet/run.sh"
    )

    found_script=""

    for start_script in "${potential_scripts[@]}"; do

        if [ -f "${start_script}" ]; then

            if [ ! -x "${start_script}" ]; then
                chmod +x "${start_script}"
            fi

            if [ -x "${start_script}" ]; then
                found_script="${start_script}"
                break
            fi

        fi

    done


    # ----------------------------------------------
    # Start node
    # ----------------------------------------------

    if [ -n "${found_script}" ]; then

        echo "Starting Hyphanet: ${found_script}"

        "${found_script}" start

        echo "Waiting for Hyphanet..."
        sleep 15

        if [ ! -f "${WRAPPER_LOG_PATH}" ]; then
            echo "Creating wrapper.log..."
            touch "${WRAPPER_LOG_PATH}"
        fi

        echo "Following log: ${WRAPPER_LOG_PATH}"

        tail -f "${WRAPPER_LOG_PATH}"

    else

        echo "ERROR: Could not find a valid start script!"

        printf "Searched paths:\n"
        printf " - %s\n" "${potential_scripts[@]}"

        ls -laR "${HYPHANET_HOME}" || true

        exit 1

    fi

else

    exec "$@"

fi
