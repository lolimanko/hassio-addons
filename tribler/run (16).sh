#!/bin/bash
set -euo pipefail

OPTS=/data/options.json
opt() { python3 -c "import json;print(json.load(open('$OPTS')).get('$1',''))"; }

API_KEY="$(opt api_key)"
API_PORT="$(opt api_port)"
DOWNLOAD_DIR="$(opt download_dir)"
EXPOSE_API="$(opt expose_api)"
INTERNAL_PORT=18085   # Tribler 實際監聽的埠（只在 127.0.0.1），對外一律經過 nginx

# 沒填 API key 就產生一組並持久化，避免 Web UI 裸奔
if [ -z "$API_KEY" ]; then
  KEYFILE=/data/generated_api_key
  [ -s "$KEYFILE" ] || head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' > "$KEYFILE"
  API_KEY="$(cat "$KEYFILE")"
fi

# 設定檔與下載目錄：設定放 /data（隨 add-on 備份），下載放 /media
export HOME=/data/home
mkdir -p "$HOME/.Tribler" "$DOWNLOAD_DIR"
ln -sfn "$DOWNLOAD_DIR" "$HOME/Downloads"
ln -sfn "$DOWNLOAD_DIR" "$HOME/TriblerDownloads"

# 清掉舊版 add-on（0.1.5 ~ 0.2.1）留下的「只含 api 區段」的不完整設定檔：
# Tribler 不會替缺少的區段補預設值，會因 KeyError: 'interfaces' 崩潰。
python3 - <<'EOF_PY'
import glob, json, os
root = os.path.expanduser("~/.Tribler")
for p in glob.glob(os.path.join(root, "*", "configuration.json")):
    try:
        cfg = json.load(open(p))
    except ValueError:
        continue
    if isinstance(cfg, dict) and set(cfg) <= {"api"}:
        os.remove(p)
        print(f"[tribler-addon] removed incomplete config from an older add-on version: {p}")
EOF_PY

# Tribler 只聽 127.0.0.1:$INTERNAL_PORT（預設值），埠與金鑰靠環境變數指定，不再改它的設定檔
export CORE_API_PORT="$INTERNAL_PORT"
export CORE_API_KEY="$API_KEY"
export LANG=C.UTF-8

# ---- nginx：Ingress（8099）+ 選用的直連埠 ----
python3 - "$API_PORT" "$INTERNAL_PORT" "$API_KEY" "$EXPOSE_API" <<'EOF_PY'
import re, sys
port, internal, key, expose = sys.argv[1:5]
if not re.fullmatch(r"[A-Za-z0-9._~-]+", key):
    sys.exit("[tribler-addon] ERROR: api_key 只能包含英數字與 . _ ~ -（會用在網址與 nginx 設定中）")
direct = ""
if expose.lower() == "true":
    # 直連埠：單純轉發，不帶金鑰（Web UI 自己會帶），不改寫內容
    direct = f"""
  server {{
    listen {port};
    location / {{
      proxy_pass http://127.0.0.1:{internal};
      proxy_http_version 1.1;
      proxy_set_header Host $http_host;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
      proxy_buffering off;
      proxy_read_timeout 3600s;
    }}
  }}
"""
tpl = open("/opt/nginx.conf.template").read()
shim = " ".join(open("/opt/ingress_shim.js").read().split())
conf = (tpl.replace("@DIRECT_SERVER@", direct)
           .replace("@SHIM@", shim)
           .replace("@API_KEY@", key)
           .replace("@INTERNAL_PORT@", internal))
open("/tmp/nginx.conf", "w").write(conf)
EOF_PY
if nginx -t -c /tmp/nginx.conf; then
  nginx -c /tmp/nginx.conf &
  echo "[tribler-addon] Ingress proxy started on :8099"
else
  echo "[tribler-addon] WARNING: nginx 設定檢查失敗，Ingress 不可用（Tribler 仍會啟動）"
fi

if [ "$EXPOSE_API" = "true" ]; then
  echo "[tribler-addon] 直連 Web UI: http://<HA-IP>:${API_PORT}/ui/#/downloads/all?key=${API_KEY}"
fi

# 啟動前先確認 Rust 擴充模組可載入（失敗時日誌會直接顯示原因）
python3 -c "import ipv8_rust_tunnels; print('[tribler-addon] ipv8_rust_tunnels OK')"

# 啟動 headless（-s = server 模式，不開瀏覽器）
export PYTHONPATH="/tribler/src:/tribler/pyipv8:${PYTHONPATH:-}"
cd /tribler/src
exec python3 run_tribler.py -s
