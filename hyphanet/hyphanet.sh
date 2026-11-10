#!/bin/bash
set -e

# ==================================================
# 1. Environment
# ==================================================

HYPHANET_HOME="${HYPHANET_HOME:-/opt/hyphanet}"
HYPHANET_DATA="${HYPHANET_DATA:-/config}"

#SOCAT_LISTEN_PORT=8123
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
#echo "SOCAT Port:    ${SOCAT_LISTEN_PORT}"
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

else
    echo "Existing freenet.ini found."
fi


# ==================================================
# 4. Update freenet.ini
# ==================================================

echo "[3/6] Updating freenet.ini..."

TMP_INI="${CONFIG_INI}.tmp"

awk \
    -v data="${HYPHANET_DATA}" \
    -v fproxy_port="${HYPHANET_FPROXY_PORT}" '
BEGIN {
    FS = "="
    OFS = "="

    # All managed configuration keys
    count = 0

    keys[++count] = "ssl.sslKeyStore"
    values["ssl.sslKeyStore"] = data "/datastore/certs"

    keys[++count] = "node.downloadsDir"
    values["node.downloadsDir"] = data "/downloads"

    keys[++count] = "node.install.persistentTempDir"
    values["node.install.persistentTempDir"] = data "/persistent-temp"

    keys[++count] = "node.install.storeDir"
    values["node.install.storeDir"] = data "/datastore"

    keys[++count] = "node.install.pluginStoresDir"
    values["node.install.pluginStoresDir"] = data "/plugin-data"

    keys[++count] = "node.install.tempDir"
    values["node.install.tempDir"] = data "/temp"

    keys[++count] = "node.install.pluginDir"
    values["node.install.pluginDir"] = data "/plugins"

    keys[++count] = "fproxy.enabled"
    values["fproxy.enabled"] = "true"

    keys[++count] = "fproxy.port"
    values["fproxy.port"] = fproxy_port

    keys[++count] = "fproxy.bindTo"
    values["fproxy.bindTo"] = "0.0.0.0"

    keys[++count] = "fproxy.allowedHosts"
    values["fproxy.allowedHosts"] = "*"

    keys[++count] = "fproxy.allowedHostsFullAccess"
    values["fproxy.allowedHostsFullAccess"] = "*"

    for (i = 1; i <= count; i++) {
        managed[keys[i]] = 1
    }
}

{
    # Remove End; it will be written once at the end
    if ($0 ~ /^[[:space:]]*End[[:space:]]*$/) {
        next
    }

    # Identify configuration key
    key = $1
    sub(/^[[:space:]]*/, "", key)
    sub(/[[:space:]]*$/, "", key)

    # Replace managed keys only once
    if (key in managed) {
        if (!(key in written)) {
            print key "=" values[key]
            written[key] = 1
        }
        next
    }

    # Preserve all other original lines
    print
}

END {
    # Add managed keys that did not exist
    for (i = 1; i <= count; i++) {
        key = keys[i]

        if (!(key in written)) {
            print key "=" values[key]
        }
    }

    # Restore exactly one End at the end
    print "End"
}
' "${CONFIG_INI}" > "${TMP_INI}"

mv "${TMP_INI}" "${CONFIG_INI}"

echo "Configuration after update:"
cat "${CONFIG_INI}"


# ==================================================
# 5. Initialize other persistent files
# ==================================================

echo "[4/6] Preparing persistent files..."

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
# 6. Configure Java Service Wrapper
# ==================================================

echo "[5/6] Configuring Wrapper..."

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
# 7. Start Hyphanet
# ==================================================

if [ "$1" = "start" ]; then

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

        echo "CONFIG BEFORE START:"
        grep -nE '^(ssl\.sslKeyStore|node\.downloadsDir|node\.install\.|fproxy\.)|^End$' \
            "${CONFIG_INI}" || true

        "${found_script}" start

        echo "Waiting for Hyphanet..."
        sleep 15

        echo "CONFIG AFTER START:"
        grep -nE '^(ssl\.sslKeyStore|node\.downloadsDir|node\.install\.|fproxy\.)|^End$' \
            "${CONFIG_INI}" || true

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
