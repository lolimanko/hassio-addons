"""Tribler 啟動後，用它自己的 REST API 把「預設下載目錄」設成 add-on 的 download_dir。
不直接改 configuration.json（Tribler 不會替不完整的設定檔補預設值，會崩潰）。

規則：只在目前值是 add-on 內部預設（/data/home/...）或是上次由本 add-on 設定的值時才覆蓋，
所以使用者自己在 Tribler 介面改過的目錄不會被每次重啟蓋掉。"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

port, key, want = sys.argv[1:4]
base = f"http://127.0.0.1:{port}"
MARK = "/data/applied_download_dir"


def log(msg):
    print(f"[tribler-addon] {msg}", flush=True)


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        base + path, data=data, method=method,
        headers={"X-Api-Key": key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.load(r)


def find(d, k):
    """在巢狀 dict 中找出名為 k 的欄位值。"""
    if isinstance(d, dict):
        for kk, v in d.items():
            if kk == k:
                return v
            r = find(v, k)
            if r is not None:
                return r
    return None


cur = None
for _ in range(180):
    try:
        cur = find(call("GET", "/api/settings"), "saveas")
        break
    except Exception:
        time.sleep(2)
else:
    log("WARNING: Tribler API 沒有回應，未套用預設下載目錄")
    sys.exit(0)

last = open(MARK).read().strip() if os.path.exists(MARK) else ""
log(f"預設下載目錄（目前）: {cur}")
if cur == want:
    open(MARK, "w").write(want)
    sys.exit(0)

internal_default = isinstance(cur, str) and cur.startswith("/data/home")
if not (cur in (None, "") or internal_default or cur == last):
    log(f"保留你在 Tribler 介面設定的目錄: {cur}（add-on 的 download_dir 是 {want}）")
    sys.exit(0)

try:
    call("POST", "/api/settings", {"libtorrent": {"download_defaults": {"saveas": want}}})
except urllib.error.HTTPError as e:
    log(f"WARNING: POST /api/settings 失敗: HTTP {e.code} {e.read()[:300]!r}")
except Exception as e:
    log(f"WARNING: POST /api/settings 失敗: {e}")

new = find(call("GET", "/api/settings"), "saveas")
log(f"預設下載目錄（套用後）: {new}")
if new == want:
    open(MARK, "w").write(want)
else:
    log("WARNING: 套用後的值與預期不同，請到 Tribler「設定 → 一般 → 儲存檔案到」手動設定")
