"""挑出最新且「編譯後的模組確實匯出」EndpointNotOpenError 的 ipv8-rust-tunnels 版本。
做法：下載各版本的預編譯 wheel（任一平台皆可，只為了檢查），在 .so 二進位裡搜尋該名稱。
（原始碼文字比對不可靠：註解/文件也會含有該字串。）結果版本號印在 stdout，過程印在 stderr。"""
import io
import json
import sys
import urllib.request
import zipfile

NAME = "ipv8-rust-tunnels"
NEEDLE = b"EndpointNotOpenError"


def log(msg):
    print(f"[pick] {msg}", file=sys.stderr, flush=True)


def key(v):
    return tuple(int(x) if x.isdigit() else 0 for x in v.split("."))


def pick_wheel(files):
    wheels = [f for f in files if f["packagetype"] == "bdist_wheel" and not f.get("yanked")]
    for f in wheels:
        n = f["filename"]
        if "manylinux" in n and ("x86_64" in n or "aarch64" in n):
            return f
    return None


data = json.load(urllib.request.urlopen(f"https://pypi.org/pypi/{NAME}/json", timeout=60))
for ver in sorted(data["releases"], key=key, reverse=True):
    w = pick_wheel(data["releases"][ver])
    if not w:
        log(f"{ver}: skip (no linux wheel to inspect)")
        continue
    raw = urllib.request.urlopen(w["url"], timeout=180).read()
    found = False
    with zipfile.ZipFile(io.BytesIO(raw)) as zf:
        for name in zf.namelist():
            if name.endswith(".so") and NEEDLE in zf.read(name):
                found = True
                break
    log(f"{ver}: {'HAS' if found else 'no'} {NEEDLE.decode()} ({w['filename']})")
    if found:
        print(ver)
        sys.exit(0)
sys.exit(f"[pick] no {NAME} version exports {NEEDLE.decode()}")
