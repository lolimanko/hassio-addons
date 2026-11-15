#!/bin/bash
set -e

# 以 root 執行（HAOS add-on 預設就是 root），不要整體降權
chown -R www-data:www-data "${HASHTOPOLIS_PATH}"
chmod -R g+w "${HASHTOPOLIS_PATH}"


# 確保 Apache log 目錄存在（root 啟動的 Apache 可直接寫入）
mkdir -p /var/log/apache2

ssl=$(jq -r '.SSL' /data/options.json)
if [ "$ssl" = "true" ]; then
    a2enmod ssl && a2ensite default-ssl
fi

export HASHTOPOLIS_DB_TYPE=$(jq -r '.hashtopolis_db_type' /data/options.json)
export HASHTOPOLIS_DB_USER=$(jq -r '.hashtopolis_db_user' /data/options.json)
export HASHTOPOLIS_DB_PASS=$(jq -r '.hashtopolis_db_pass' /data/options.json)
export HASHTOPOLIS_DB_HOST=$(jq -r '.hashtopolis_db_host' /data/options.json)
export HASHTOPOLIS_DB_PORT=$(jq -r '.hashtopolis_db_port' /data/options.json)
export HASHTOPOLIS_DB_DATABASE=$(jq -r '.hashtopolis_db_database' /data/options.json)
export HASHTOPOLIS_ADMIN_USER=$(jq -r '.hashtopolis_admin_user' /data/options.json)
export HASHTOPOLIS_ADMIN_PASSWORD=$(jq -r '.hashtopolis_admin_password' /data/options.json)
export HASHTOPOLIS_BACKEND_URL=$(jq -r '.hashtopolis_backend_url' /data/options.json)
export HASHTOPOLIS_FRONTEND_URLS=$(jq -r '.hashtopolis_frontend_urls' /data/options.json)

# 用 exec 讓 SIGTERM 能正確傳給 Apache；降權只在 docker-entrypoint.sh 內針對 PHP 步驟進行
exec gosu www-data /usr/local/bin/docker-entrypoint.sh
