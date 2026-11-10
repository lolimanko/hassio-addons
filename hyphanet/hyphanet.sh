#!/bin/bash
set -e

# ==================================================
# 1. Environment
# ==================================================

HYPHANET_HOME="${HYPHANET_HOME:-/opt/hyphanet}"
HYPHANET_DATA="${HYPHANET_DATA:-/config}"

HYPHANET_FPROXY_PORT=8888

RUN_SCRIPT="${HYPHANET_HOME}/run.sh"
CONFIG_INI="${HYPHANET_DATA}/freenet.ini"
WRAPPER_CONF="${HYPHANET_HOME}/wrapper.conf"
WRAPPER_LOG_PATH="${HYPHANET_DATA}/wrapper.log"

echo "========================================"
echo " Hyphanet Entrypoint"
echo "========================================"
echo "User:          $(whoami)"
echo "Home:          ${HYPHANET_HOME}"
echo "Data:          ${HYPHANET_DATA}"
echo "FProxy Port:   ${HYPHANET_FPROXY_PORT}"
echo "========================================"


# ==================================================
# 2. Prepare persistent storage
# ==================================================

echo "[1/7] Preparing persistent storage..."

mkdir -p "${HYPHANET_DATA}"

PERSISTENT_DIRS=(
    "config"
    "state"
    "noderef"
    "run"
    "downloads"
    "persistent-temp"
    "datastore/certs"
    "plugin-data"
    "temp"
    "plugins"
)

for item in "${PERSISTENT_DIRS[@]}"; do
    mkdir -p "${HYPHANET_DATA}/${item}"
done


# ==================================================
# 3. Initialize freenet.ini
# ==================================================

echo "[2/7] Checking freenet.ini..."

if [ ! -f "${CONFIG_INI}" ]; then
    if [ ! -f "${HYPHANET_HOME}/freenet.ini" ]; then
        echo "ERROR: Initial freenet.ini not found!"
        exit 1
    fi

    cp -a "${HYPHANET_HOME}/freenet.ini" "${CONFIG_INI}"
    echo "Initialized freenet.ini."
else
    echo "Existing freenet.ini found."
fi


# ==================================================
# 4. Initialize persistent files
# ==================================================

echo "[3/7] Preparing persistent files..."

PERSISTENT_FILES=(
    "freenet.ini.bak"
    "node.random"
    "master.keys"
    "wrapper.log"
)

for item in "${PERSISTENT_FILES[@]}"; do
    src="${HYPHANET_HOME}/${item}"
    dest="${HYPHANET_DATA}/${item}"

    if [ ! -e "${dest}" ] && [ -f "${src}" ]; then
        cp -a "${src}" "${dest}"
    fi
done

SEED_SOURCE="${HYPHANET_HOME}/seednodes.fref"
SEED_DEST="${HYPHANET_DATA}/noderef/seednodes.fref"

if [ ! -e "${SEED_DEST}" ] && [ -f "${SEED_SOURCE}" ]; then
    cp -a "${SEED_SOURCE}" "${SEED_DEST}"
fi


# ==================================================
# 5. Update freenet.ini
# ==================================================

echo "[4/7] Updating freenet.ini..."

TMP_INI="${CONFIG_INI}.tmp"

awk \
    -v data="${HYPHANET_DATA}" \
    -v fproxy_port="${HYPHANET_FPROXY_PORT}" '
BEGIN {
    FS = "="
    OFS = "="

    count = 0

    keys[++count] = "node.masterKeyFile"
    values["node.masterKeyFile"] = data "/master.keys"

    keys[++count] = "node.install.cfgDir"
    values["node.install.cfgDir"] = data "/config"

    keys[++count] = "node.install.userDir"
    values["node.install.userDir"] = data "/state"

    keys[++count] = "node.install.nodeDir"
    values["node.install.nodeDir"] = data "/noderef"

    keys[++count] = "node.install.runDir"
    values["node.install.runDir"] = data "/run"

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
    if ($0 ~ /^[[:space:]]*End[[:space:]]*$/) {
        next
    }

    key = $1
    sub(/^[[:space:]]*/, "", key)
    sub(/[[:space:]]*$/, "", key)

    if (key in managed) {
        if (!(key in written)) {
            print key "=" values[key]
            written[key] = 1
        }
        next
    }

    print
}

END {
    for (i = 1; i <= count; i++) {
        key = keys[i]

        if (!(key in written)) {
            print key "=" values[key]
        }
    }

    print "End"
}
' "${CONFIG_INI}" > "${TMP_INI}"

mv "${TMP_INI}" "${CONFIG_INI}"

echo "Configuration updated."


# ==================================================
# 6. Verify configuration
# ==================================================

echo "[5/7] Verifying freenet.ini..."

END_COUNT=$(grep -c '^End$' "${CONFIG_INI}" || true)

if [ "${END_COUNT}" -ne 1 ]; then
    echo "ERROR: freenet.ini must contain exactly one End!"
    exit 1
fi

if [ "$(tail -n 1 "${CONFIG_INI}")" != "End" ]; then
    echo "ERROR: End is not the last line!"
    exit 1
fi

echo "freenet.ini structure OK."


# ==================================================
# 7. Configure Wrapper and start Hyphanet
# ==================================================

echo "[6/7] Configuring Wrapper..."

if [ ! -f "${WRAPPER_CONF}" ]; then
    echo "ERROR: wrapper.conf not found: ${WRAPPER_CONF}"
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

echo "Wrapper configured."


if [ "${1:-}" = "start" ]; then

    echo "[7/7] Starting Hyphanet..."

    if [ ! -f "${RUN_SCRIPT}" ]; then
        echo "ERROR: run.sh not found: ${RUN_SCRIPT}"
        exit 1
    fi

    bash "${RUN_SCRIPT}" start

    echo "Waiting for Hyphanet..."
    sleep 15

    if [ ! -f "${WRAPPER_LOG_PATH}" ]; then
        touch "${WRAPPER_LOG_PATH}"
    fi

    echo "Following log: ${WRAPPER_LOG_PATH}"

    exec tail -n 100 -F "${WRAPPER_LOG_PATH}"

else
    exec "$@"
fi
