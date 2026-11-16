#!/bin/bash
set -euo pipefail

OPTS=/data/options.json
opt() { python3 -c "import json;print(json.load(open('$OPTS')).get('$1',''))"; }

API_KEY="$(opt api_key)"
API_PORT="$(opt api_port)"
DOWNLOAD_DIR="$(opt download_dir)"
EXPOSE_API="$(opt expose_api)"

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

# 設定 REST API / Web UI 綁定位址：
#   expose_api=true  → 0.0.0.0（區網可直連 API 埠）
#   expose_api=false → 127.0.0.1（只能經由側邊欄 Ingress 存取）
# Tribler 從 git 原始碼啟動時，狀態目錄的版本資料夾叫 "git"（不是 "8.0"），
# 所以 git、8.0 與任何已存在的版本目錄都一併處理。
python3 - "$API_PORT" "$API_KEY" "$EXPOSE_API" <<'PYEOF'
import glob, json, os, sys
port, key = int(sys.argv[1]), sys.argv[2]
host = "0.0.0.0" if sys.argv[3].lower() == "true" else "127.0.0.1"
root = os.path.expanduser("~/.Tribler")
paths = set(glob.glob(os.path.join(root, "*", "configuration.json")))
for ver in ("git", "8.0"):
    paths.add(os.path.join(root, ver, "configuration.json"))
for path in sorted(paths):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    try:
        cfg = json.load(open(path)) if os.path.exists(path) else {}
    except ValueError:
        cfg = {}
    api = cfg.setdefault("api", {})
    api.update({"http_enabled": True, "http_host": host, "http_port": port, "key": key})
    json.dump(cfg, open(path, "w"), indent=2)
    print(f"[tribler-addon] config patched ({host}): {path}")
PYEOF

export CORE_API_PORT="$API_PORT"
export CORE_API_KEY="$API_KEY"
export LANG=C.UTF-8

# ---- Ingress：產生 nginx 設定並在背景啟動 ----
python3 - "$API_PORT" "$API_KEY" <<'PYEOF'
import re, sys
port, key = sys.argv[1], sys.argv[2]
if not re.fullmatch(r"[A-Za-z0-9._~-]+", key):
    sys.exit("[tribler-addon] ERROR: api_key 只能包含英數字與 . _ ~ -（會用在網址與 nginx 設定中）")
tpl = open("/opt/nginx.conf.template").read()
shim = " ".join(open("/opt/ingress_shim.js").read().split())
conf = tpl.replace("@SHIM@", shim).replace("@API_KEY@", key).replace("@API_PORT@", port)
open("/tmp/nginx.conf", "w").write(conf)
PYEOF
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
