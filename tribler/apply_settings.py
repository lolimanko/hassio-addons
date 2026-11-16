"""Tribler 啟動後，用它自己的 REST API 套用 add-on 選項：預設下載目錄、BitTorrent 連入埠。
不直接改 configuration.json（Tribler 不會替不完整的設定檔補預設值，會崩潰）。

- 下載目錄：只在目前值是 add-on 內部預設（/data/home/...）或上次由本 add-on 設定的值時才覆蓋，
  所以使用者自己在 Tribler 介面改過的目錄不會被每次重啟蓋掉。
- 連入埠：一律以 add-on 選項為準。libtorrent 的埠在 session 建立時就決定了，
  所以埠被改動後會請 run.sh 重啟 Tribler 一次（每個容器生命週期最多一次，避免無限重啟）。"""
import json
import os
import signal
import sys
import time
import urllib.error
import urllib.request

port, key, want_dir, want_bt = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
base = f"http://127.0.0.1:{port}"
DIR_MARK = "/data/applied_download_dir"
PID_FILE = "/tmp/tribler.pid"
RESTART_FLAG = "/tmp/restart_tribler"
RESTARTED_ONCE = "/tmp/restarted_once"


def log(msg):
    print(f"[tribler-addon] {msg}", flush=True)


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        base + path, data=data, method=method,
        headers={"X-Api-Key": key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.load(r)


def settings():
    r = call("GET", "/api/settings")
    return r.get("settings", r) if isinstance(r, dict) else {}


def get(d, *path):
    for p in path:
        if not isinstance(d, dict):
            return None
        d = d.get(p)
    return d


s = None
for _ in range(180):
    try:
        s = settings()
        break
    except Exception:
        time.sleep(2)
if s is None:
    log("WARNING: Tribler API 沒有回應，未套用 add-on 選項")
    sys.exit(0)

cur_dir = get(s, "libtorrent", "download_defaults", "saveas")
cur_bt = get(s, "libtorrent", "port")
last_dir = open(DIR_MARK).read().strip() if os.path.exists(DIR_MARK) else ""
log(f"預設下載目錄（目前）: {cur_dir} ；BitTorrent 連入埠（目前）: {cur_bt}")

lt = {}
if cur_bt is None:
    log("WARNING: 設定中找不到 libtorrent/port，略過連入埠")
elif cur_bt != want_bt:
    lt["port"] = want_bt

internal_default = isinstance(cur_dir, str) and cur_dir.startswith("/data/home")
if cur_dir == want_dir:
    open(DIR_MARK, "w").write(want_dir)
elif cur_dir in (None, "") or internal_default or cur_dir == last_dir:
    lt["download_defaults"] = {"saveas": want_dir}
else:
    log(f"保留你在 Tribler 介面設定的下載目錄: {cur_dir}（add-on 的 download_dir 是 {want_dir}）")

if not lt:
    sys.exit(0)

try:
    call("POST", "/api/settings", {"libtorrent": lt})
except urllib.error.HTTPError as e:
    log(f"WARNING: POST /api/settings 失敗: HTTP {e.code} {e.read()[:300]!r}")
except Exception as e:
    log(f"WARNING: POST /api/settings 失敗: {e}")

s2 = settings()
new_dir = get(s2, "libtorrent", "download_defaults", "saveas")
new_bt = get(s2, "libtorrent", "port")
log(f"預設下載目錄（套用後）: {new_dir} ；BitTorrent 連入埠（套用後）: {new_bt}")

if "download_defaults" in lt:
    if new_dir == want_dir:
        open(DIR_MARK, "w").write(want_dir)
    else:
        log("WARNING: 下載目錄套用後與預期不同，請到 Tribler「設定 → 一般 → 儲存檔案到」手動設定")

if "port" in lt:
    if new_bt != want_bt:
        log("WARNING: 連入埠套用後與預期不同，未重啟")
    elif os.path.exists(RESTARTED_ONCE):
        log("WARNING: 已重啟過一次但埠仍不同，為避免無限重啟，這次不再重啟")
    else:
        log(f"連入埠已改為 {want_bt}，重啟 Tribler 一次讓 libtorrent 使用新埠…")
        open(RESTART_FLAG, "w").write("1")
        try:
            os.kill(int(open(PID_FILE).read().strip()), signal.SIGTERM)
        except Exception as e:
            log(f"WARNING: 無法重啟 Tribler（{e}），新埠會在下次啟動生效")
