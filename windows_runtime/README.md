# Windows Runtime

[繁體中文](#繁體中文) | [English](#english)

---

## 繁體中文

在 Home Assistant OS (HAOS) 上，透過 **Box86 / Box64 + Wine** 在 ARM64 (aarch64) 機器上執行 32 位元與 64 位元的 Windows 程式，並以 **VNC** 遠端操作畫面。

> ⚠️ 實驗性專案：Windows 程式透過 x86 模擬器執行，效能與相容性會因程式而異。

### 功能特色

- **同時支援 32 / 64 位元**：32 位元使用 Box86 + wine32，64 位元使用 Box64 + wine64，兩者使用各自獨立的 Wine prefix。
- **自動判斷位元數**：`arch_mode` 設為 `auto` 時，會讀取 EXE 的 PE 標頭決定使用哪一種模式。
- **VNC 遠端桌面**：內建 Xvfb + Fluxbox + x11vnc，埠號 5900。
- **多語系與 CJK 字型**：可選日文、繁體中文、簡體中文、韓文、英文；自動設定對應的 locale 與字型替換（MS Gothic、微軟正黑體、SimSun、Malgun Gothic 等對應到 Noto CJK）。
- **程式同目錄設定檔**：Windows 程式以 EXE 所在目錄作為工作目錄，相對路徑的設定檔可正常讀寫。
- **縮小 HAOS 備份**：Wine prefix 預設放在 `/media`，不會被 HAOS 備份；也可改回放在 `/config`。
- **日誌**：同時輸出到 Supervisor 日誌與 `/config/logs/run.log`（自動保留約 1000 行）。

### 系統需求

- Home Assistant OS，且硬體為 **aarch64 (ARM64)**，例如 Raspberry Pi 4/5。
- 建議 4 GB 以上記憶體（x86 模擬器與 Wine 較吃資源；自行編譯映像檔時需求更高）。
- 能連線到 `ghcr.io`，以下載預先建置好的映像檔。

### 安裝

本 add-on 使用**預先建置好的映像檔**（`config.yaml` 中的 `image`），HA 會直接從 GitHub Container Registry 下載，不需要在 HAOS 上編譯，安裝速度快很多：

```
ghcr.io/lolimanko/{arch}-windows-runtime
```

`{arch}` 會由 Supervisor 自動替換成 `aarch64`，映像檔標籤 (tag) 與 `config.yaml` 的 `version` 相同。

1. 將 add-on 資料夾複製到 HAOS 的 `/addons/windows_runtime/`（可透過 Samba 或 SSH 的 `addons` 分享）。資料夾內只需要：

   ```
   windows_runtime/
   ├── config.yaml
   ├── README.md
   └── translations/
       ├── en.yaml
       └── zh-Hant.yaml
   ```

2. 在 HA：**設定 → 附加元件 → 附加元件商店**，右上角選單選「檢查更新」，在 **Local add-ons** 找到 *Windows Runtime*。
3. 按「安裝」，等待映像檔下載完成。
4. 設定選項後啟動，並查看日誌確認狀態。

> 如果安裝時出現找不到映像檔的錯誤，請確認 GHCR 上的套件已設為 **Public**，且存在與 `version` 相同的標籤。

### 自行建置映像檔（維護者）

要修改 `Dockerfile` 或 `run.sh` 時，需要重新建置並推送映像檔。建置資料夾內需包含：

```
build/
├── Dockerfile
├── run.sh
├── libwine_8.0~repack-4_i386.deb
├── wine32-preloader_8.0~repack-4_i386.deb
├── wine32_8.0~repack-4_i386.deb
├── libwine_8.0~repack-4_amd64.deb
├── wine64-preloader_8.0~repack-4_amd64.deb
├── wine64_8.0~repack-4_amd64.deb
└── wine_8.0~repack-4_all.deb
```

七個 `.deb` 的版本必須一致，可從 Debian 官方套件庫下載：

```bash
BASE=http://deb.debian.org/debian/pool/main/w/wine
wget $BASE/libwine_8.0~repack-4_i386.deb
wget $BASE/wine32-preloader_8.0~repack-4_i386.deb
wget $BASE/wine32_8.0~repack-4_i386.deb
wget $BASE/libwine_8.0~repack-4_amd64.deb
wget $BASE/wine64-preloader_8.0~repack-4_amd64.deb
wget $BASE/wine64_8.0~repack-4_amd64.deb
wget $BASE/wine_8.0~repack-4_all.deb
```

若 Debian 已更新版本號（例如 `+deb12u1`），請把 Dockerfile 內的檔名一併修改。

建置並推送（在可建置 arm64 映像檔的機器上，標籤要與 `config.yaml` 的 `version` 一致）：

```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io -u lolimanko --password-stdin

docker buildx build --platform linux/arm64 \
  -t ghcr.io/lolimanko/aarch64-windows-runtime:0.4.0 \
  -t ghcr.io/lolimanko/aarch64-windows-runtime:latest \
  --push .
```

每次更新映像檔時，請同步調高 `config.yaml` 的 `version` 並推送對應標籤，HA 才會偵測到更新。

### 設定選項

| 選項 | 預設值 | 說明 |
| --- | --- | --- |
| `app_exe` | `notepad.exe` | 要啟動的 Windows 程式。填檔名時依序搜尋 `/share/windows-apps`、`/media/windows-apps`；也可填完整絕對路徑，例如 `/media/apps/foo/foo.exe`。 |
| `arch_mode` | `auto` | `auto` 自動判斷；`32` 或 `64` 強制指定。 |
| `locale` | `ja_JP.UTF-8` | 可選 `ja_JP.UTF-8`、`zh_TW.UTF-8`、`zh_CN.UTF-8`、`ko_KR.UTF-8`、`en_US.UTF-8`。影響 Wine 的 ANSI 碼頁與字型替換，更換後請重啟。 |
| `prefix_location` | `media` | `media`：Wine prefix 放在 `/media/windows_runtime/`，不進 HAOS 備份（預設）；`config`：放在 add-on 設定目錄，會進備份。若 `/media` 不可寫入或不支援符號連結，會自動退回 `config`。 |
| `vnc_password` | （空） | VNC 密碼。**留空時會使用預設值 `123456`，建議自行設定。** |

### 目錄說明

| 路徑 | 用途 |
| --- | --- |
| `/share/windows-apps/` | 放置 Windows 程式（預設搜尋位置） |
| `/media/windows-apps/` | 放置 Windows 程式（第二搜尋位置，不進備份） |
| `/media/windows_runtime/wineprefix32`、`wineprefix64` | Wine prefix（`prefix_location: media` 時） |
| `/config/wineprefix32`、`wineprefix64` | Wine prefix（`prefix_location: config` 時） |
| `/config/logs/run.log` | 啟動與執行日誌 |
| `/config/vnc.pass` | VNC 密碼檔 |

### 使用方式

1. 把程式（含它的設定檔、資源檔）放進 `/share/windows-apps/` 或 `/media/windows-apps/`。
2. 在設定中填入 `app_exe`，儲存並啟動 add-on。
3. 用 VNC 用戶端連線到 `HAOS的IP:5900`，輸入密碼即可看到程式畫面。

### 位元模式與 prefix

- 一個容器一次只會執行一種位元模式。需要同時跑 32 與 64 位元程式時，請安裝兩份 add-on（不同 slug），各自指定 `arch_mode`。
- 32 位元與 64 位元各用獨立的 prefix，互不影響。
- 想重新套用字型替換：刪除 prefix 目錄下的 `.fonts_done_*` 檔案後重啟。想完全重置環境：停止 add-on 後刪除整個 prefix 資料夾。

### 關於備份

HAOS 備份 add-on 時包含 `/config`，但不含 `/media`。Wine prefix 通常有數百 MB，預設放在 `/media` 可明顯縮小備份檔。代價是：

- 還原備份後 Wine 環境會重新建立，prefix 內安裝的東西與登錄檔設定不會還原。
- 需要被備份的資料請放在 `/config`，或將 `prefix_location` 設為 `config`。

### 疑難排解

- **安裝時下載不到映像檔**：確認 HAOS 能連到 `ghcr.io`、GHCR 套件為 Public，且標籤與 `version` 一致。
- **日誌沒有輸出 / VNC 連不上**：SSH 進 HAOS 後執行 `docker ps -a`、`docker logs --tail 100 addon_local_windows_runtime`，並檢查 `/config/logs/run.log`。
- **第一次啟動很久**：初始化 Wine prefix（`wineboot`）在模擬器下很慢，最多等待 300 秒（逾時後仍會嘗試啟動程式）。
- **自行建置映像檔時卡死或機器無反應**：多半是編譯 Box64 耗盡記憶體，可在 Dockerfile 將 `make -j2` 改成 `make -j1`，並把建置類型改為 `Release`。
- **日文（或其他 CJK）顯示成方框**：確認 `locale` 設定，並查看日誌的「系統字型」與「設定 CJK 字型替換」段落。
- **讀不到程式同目錄的設定檔**：日誌會列出工作目錄內容與是否可寫入，請對照檢查檔名大小寫與權限。
- **`[BOX64] Error initializing native lib...` 訊息**：Box64 找不到某些原生函式庫時會退回其他版本，一般可忽略。

### 已知限制

- 僅支援 aarch64。
- 未提供音效輸出與 GPU 加速。
- 效能取決於模擬器；重度 3D 或需要大量 DirectX 功能的程式可能無法正常執行。
- Wine 版本固定為 Debian 的 8.0 repack 套件。

---

## English

Run **32-bit and 64-bit Windows applications** on ARM64 (aarch64) Home Assistant OS machines using **Box86 / Box64 + Wine**, and operate them remotely through **VNC**.

> ⚠️ Experimental: Windows programs run through an x86 emulator, so performance and compatibility vary from program to program.

### Features

- **32-bit and 64-bit support**: Box86 + wine32 for 32-bit, Box64 + wine64 for 64-bit, each with its own isolated Wine prefix.
- **Automatic architecture detection**: with `arch_mode` set to `auto`, the add-on reads the EXE's PE header to choose the right mode.
- **VNC remote desktop**: Xvfb + Fluxbox + x11vnc built in, on port 5900.
- **Locales and CJK fonts**: Japanese, Traditional Chinese, Simplified Chinese, Korean or English. The matching locale and font substitutions are applied automatically (MS Gothic, Microsoft JhengHei, SimSun, Malgun Gothic, etc. are mapped to Noto CJK).
- **Config files next to the EXE**: the program's working directory is the folder containing the EXE, so relative-path config files are found and can be saved.
- **Smaller HAOS backups**: the Wine prefix lives in `/media` by default, which HAOS backups skip. You can switch it back to `/config`.
- **Logging**: output goes to both the Supervisor log and `/config/logs/run.log` (trimmed to about 1000 lines).

### Requirements

- Home Assistant OS on **aarch64 (ARM64)** hardware, such as a Raspberry Pi 4/5.
- 4 GB RAM or more is recommended (the x86 emulator and Wine are resource-hungry; building the image yourself needs even more).
- Network access to `ghcr.io` to pull the prebuilt image.

### Installation

This add-on uses a **prebuilt image** (the `image` key in `config.yaml`). Home Assistant pulls it from the GitHub Container Registry, so nothing is compiled on your HAOS machine and installation is much faster:

```
ghcr.io/lolimanko/{arch}-windows-runtime
```

The Supervisor replaces `{arch}` with `aarch64`, and the image tag matches the `version` in `config.yaml`.

1. Copy the add-on folder to `/addons/windows_runtime/` on your HAOS machine (via the Samba or SSH `addons` share). Only these files are needed:

   ```
   windows_runtime/
   ├── config.yaml
   ├── README.md
   └── translations/
       ├── en.yaml
       └── zh-Hant.yaml
   ```

2. In Home Assistant go to **Settings → Add-ons → Add-on Store**, open the top-right menu and choose "Check for updates". *Windows Runtime* appears under **Local add-ons**.
3. Click **Install** and wait for the image to download.
4. Configure the options, start the add-on and check the log.

> If installation fails because the image cannot be found, make sure the GHCR package is set to **Public** and that a tag matching `version` exists.

### Building the image yourself (maintainers)

When you change the `Dockerfile` or `run.sh`, rebuild and push the image. The build folder must contain:

```
build/
├── Dockerfile
├── run.sh
├── libwine_8.0~repack-4_i386.deb
├── wine32-preloader_8.0~repack-4_i386.deb
├── wine32_8.0~repack-4_i386.deb
├── libwine_8.0~repack-4_amd64.deb
├── wine64-preloader_8.0~repack-4_amd64.deb
├── wine64_8.0~repack-4_amd64.deb
└── wine_8.0~repack-4_all.deb
```

All seven `.deb` files must be the same version. They can be downloaded from the official Debian archive:

```bash
BASE=http://deb.debian.org/debian/pool/main/w/wine
wget $BASE/libwine_8.0~repack-4_i386.deb
wget $BASE/wine32-preloader_8.0~repack-4_i386.deb
wget $BASE/wine32_8.0~repack-4_i386.deb
wget $BASE/libwine_8.0~repack-4_amd64.deb
wget $BASE/wine64-preloader_8.0~repack-4_amd64.deb
wget $BASE/wine64_8.0~repack-4_amd64.deb
wget $BASE/wine_8.0~repack-4_all.deb
```

If Debian has published a newer revision (for example `+deb12u1`), update the file names in the Dockerfile to match.

Build and push (on a machine that can build arm64 images; the tag must equal `version` in `config.yaml`):

```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io -u lolimanko --password-stdin

docker buildx build --platform linux/arm64 \
  -t ghcr.io/lolimanko/aarch64-windows-runtime:0.4.0 \
  -t ghcr.io/lolimanko/aarch64-windows-runtime:latest \
  --push .
```

Whenever you publish a new image, also bump `version` in `config.yaml` and push the matching tag so Home Assistant detects the update.

### Options

| Option | Default | Description |
| --- | --- | --- |
| `app_exe` | `notepad.exe` | Windows program to launch. A bare file name is searched in `/share/windows-apps`, then `/media/windows-apps`. An absolute path such as `/media/apps/foo/foo.exe` also works. |
| `arch_mode` | `auto` | `auto` detects 32/64-bit; `32` or `64` forces a mode. |
| `locale` | `ja_JP.UTF-8` | One of `ja_JP.UTF-8`, `zh_TW.UTF-8`, `zh_CN.UTF-8`, `ko_KR.UTF-8`, `en_US.UTF-8`. Affects Wine's ANSI code page and font substitution. Restart after changing it. |
| `prefix_location` | `media` | `media`: Wine prefix under `/media/windows_runtime/`, excluded from HAOS backups (default). `config`: stored in the add-on config directory and included in backups. Falls back to `config` if `/media` is not writable or does not support symlinks. |
| `vnc_password` | (empty) | VNC password. **An empty value falls back to `123456`, so please set your own.** |

### Directories

| Path | Purpose |
| --- | --- |
| `/share/windows-apps/` | Put your Windows programs here (default search location) |
| `/media/windows-apps/` | Put your Windows programs here (second search location, not in backups) |
| `/media/windows_runtime/wineprefix32`, `wineprefix64` | Wine prefixes when `prefix_location: media` |
| `/config/wineprefix32`, `wineprefix64` | Wine prefixes when `prefix_location: config` |
| `/config/logs/run.log` | Startup and runtime log |
| `/config/vnc.pass` | VNC password file |

### Usage

1. Copy your program (with its config and resource files) into `/share/windows-apps/` or `/media/windows-apps/`.
2. Set `app_exe` in the add-on options, then save and start the add-on.
3. Connect a VNC client to `<HAOS IP>:5900` and enter the password to see the program.

### Architecture modes and prefixes

- A container runs one architecture mode at a time. To run 32-bit and 64-bit programs at the same time, install two copies of the add-on (different slugs) and set `arch_mode` in each.
- The 32-bit and 64-bit modes use separate prefixes and do not affect each other.
- To re-apply font substitution, delete the `.fonts_done_*` files in the prefix directory and restart. To fully reset the environment, stop the add-on and delete the whole prefix folder.

### About backups

HAOS backups of an add-on include `/config` but not `/media`. A Wine prefix is often several hundred MB, so keeping it in `/media` noticeably shrinks backups. The trade-offs:

- After restoring a backup, the Wine environment is recreated; software installed inside the prefix and registry changes are not restored.
- Data that must be backed up should go in `/config`, or set `prefix_location` to `config`.

### Troubleshooting

- **The image cannot be downloaded during installation**: check that HAOS can reach `ghcr.io`, the GHCR package is Public, and the tag matches `version`.
- **No log output / cannot connect over VNC**: SSH into HAOS and run `docker ps -a` and `docker logs --tail 100 addon_local_windows_runtime`, and check `/config/logs/run.log`.
- **First start is slow**: initializing the Wine prefix (`wineboot`) is slow under emulation; the add-on waits up to 300 seconds (it still tries to start your program after a timeout).
- **Building the image yourself hangs or the machine becomes unresponsive**: usually Box64 compilation running out of memory. In the Dockerfile change `make -j2` to `make -j1` and use the `Release` build type.
- **Japanese (or other CJK) text shows as boxes**: check the `locale` option and look at the "system fonts" and "CJK font substitution" sections of the log.
- **Config file next to the EXE is not found**: the log lists the working directory contents and whether it is writable; compare file name case and permissions.
- **`[BOX64] Error initializing native lib...` messages**: Box64 falls back to another library version when a native one is missing; these can normally be ignored.

### Known limitations

- aarch64 only.
- No audio output and no GPU acceleration.
- Performance depends on the emulator; heavy 3D programs or those needing extensive DirectX features may not work.
- The Wine version is fixed to Debian's 8.0 repack packages.
