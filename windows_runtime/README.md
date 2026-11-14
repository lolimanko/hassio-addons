# Windows Runtime

[繁體中文](#繁體中文) | [English](#english)

---

## 繁體中文

在 Home Assistant OS (HAOS) 的 ARM64 (aarch64) 機器上，執行 **32 位元與 64 位元的 Windows 程式**，並透過 **VNC** 遠端操作畫面。

> ⚠️ 實驗性專案：Windows 程式透過 x86 模擬器執行，效能與相容性會因程式而異。

### 功能特色

- **支援 32 / 64 位元程式**：兩種模式使用各自獨立的環境，互不影響。
- **自動判斷位元數**：`arch_mode` 設為 `auto` 時，會自動辨識 EXE 是 32 位元還是 64 位元。
- **VNC 遠端桌面**：內建桌面環境，用任何 VNC 用戶端連線到埠號 5900 即可操作。
- **多語系與 CJK 字型**：可選日文、繁體中文、簡體中文、韓文、英文，並自動處理中日韓字型顯示。
- **程式同目錄設定檔**：程式會以 EXE 所在資料夾作為工作目錄，放在旁邊的設定檔可以正常讀寫。
- **縮小 HAOS 備份**：Wine 環境預設放在 `/media`，不會被 HAOS 備份，備份檔更小。

### 系統需求

- Home Assistant OS，硬體為 **aarch64 (ARM64)**，例如 Raspberry Pi 4/5。
- 建議 4 GB 以上記憶體（x86 模擬器與 Wine 較吃資源）。

### 安裝

1. 在 HA 開啟 **設定 → 附加元件 → 附加元件商店**。
2. 點右上角選單 → **儲存庫**，加入本 add-on 所在的儲存庫網址：`https://github.com/lolimanko/hassio-addons`。
3. 重新整理後找到 **Windows Runtime**，按「安裝」。
4. 到「設定」分頁調整選項，再回到「資訊」分頁啟動，並在「日誌」分頁確認狀態。

### 設定選項

| 選項 | 預設值 | 說明 |
| --- | --- | --- |
| `app_exe` | `notepad.exe` | 要啟動的 Windows 程式。填檔名時依序搜尋 `/share/windows-apps`、`/media/windows-apps`；也可填完整絕對路徑，例如 `/media/apps/foo/foo.exe`。 |
| `arch_mode` | `auto` | `auto` 自動判斷；`32` 或 `64` 強制指定。 |
| `locale` | `ja_JP.UTF-8` | 可選 `ja_JP.UTF-8`、`zh_TW.UTF-8`、`zh_CN.UTF-8`、`ko_KR.UTF-8`、`en_US.UTF-8`。影響程式的字串編碼與字型顯示，更換後請重新啟動 add-on。 |
| `prefix_location` | `media` | `media`：Windows 環境放在 `/media/windows_runtime/`，不進 HAOS 備份（預設）；`config`：放在 add-on 設定目錄，會進備份。若 `/media` 不可寫入或不支援符號連結，會自動退回 `config`。 |
| `vnc_password` | （空） | VNC 密碼。**留空時會使用預設值 `123456`，建議自行設定。** |

### 目錄說明

| 路徑 | 用途 |
| --- | --- |
| `/share/windows-apps/` | 放置 Windows 程式（預設搜尋位置） |
| `/media/windows-apps/` | 放置 Windows 程式（第二搜尋位置，不進備份） |
| `/media/windows_runtime/wineprefix32`、`wineprefix64` | Windows 環境（`prefix_location: media` 時） |
| `/addon_configs/fdd0cf77_windows_runtime/wineprefix32`、`wineprefix64` | Windows 環境（`prefix_location: config` 時） |
| `/addon_configs/fdd0cf77_windows_runtime/logs/run.log` | 啟動與執行日誌 |
| `/addon_configs/fdd0cf77_windows_runtime/vnc.pass` | VNC 密碼檔 |

`/addon_configs/fdd0cf77_windows_runtime` 是這個 add-on 的設定目錄，可透過 Samba 或 SSH 存取。

### 使用方式

1. 把程式（連同它的設定檔、資源檔）放進 `/share/windows-apps/` 或 `/media/windows-apps/`。
2. 在 add-on 設定中填入 `app_exe`，儲存並啟動。
3. 用 VNC 用戶端連線到 `HAOS的IP:5900`，輸入密碼即可看到程式畫面。

### 位元模式與 Windows 環境

- 一個 add-on 一次只會執行一種位元模式。需要同時執行 32 與 64 位元程式時，請安裝兩份 add-on，各自指定 `arch_mode`。
- 32 位元與 64 位元各有獨立的 Windows 環境（`wineprefix32` / `wineprefix64`）。
- 想重新套用字型設定：刪除環境資料夾內的 `.fonts_done_*` 檔案後重啟。想完全重置：停止 add-on 後刪除整個 `wineprefix32` 或 `wineprefix64` 資料夾。

### 關於備份

HAOS 備份 add-on 時會包含 `/addon_configs/fdd0cf77_windows_runtime`，但不包含 `/media`。Windows 環境通常有數百 MB，預設放在 `/media` 可明顯縮小備份檔。代價是：

- 還原備份後 Windows 環境會重新建立，環境內安裝的軟體與登錄檔設定不會還原。
- 需要被備份的資料請放在 `/addon_configs/fdd0cf77_windows_runtime`，或把 `prefix_location` 設為 `config`。

### 疑難排解

- **安裝時下載失敗**：確認 HAOS 能連上網路，稍後再試一次。
- **VNC 連不上或日誌沒有輸出**：先看 add-on 的「日誌」分頁，並檢查 `/addon_configs/fdd0cf77_windows_runtime/logs/run.log`，確認 add-on 已啟動、埠號 5900 有對應。
- **第一次啟動很久**：初始化 Windows 環境在模擬器下很慢，最多會等待 300 秒（逾時後仍會嘗試啟動程式），請耐心等待。
- **日文（或其他 CJK）顯示成方框**：確認 `locale` 設定符合程式語言，更換後重新啟動。
- **讀不到程式同目錄的設定檔**：日誌會列出程式所在資料夾的內容與是否可寫入，請對照檢查檔名大小寫與權限。
- **日誌出現 `[BOX64] Error initializing native lib...`**：這是模擬器找不到某些原生函式庫時的提示，會自動退回其他版本，一般可忽略。

### 已知限制

- 僅支援 aarch64。
- 未提供音效輸出與 GPU 加速。
- 效能取決於模擬器；重度 3D 或需要大量 DirectX 功能的程式可能無法正常執行。

---

## English

Run **32-bit and 64-bit Windows applications** on ARM64 (aarch64) Home Assistant OS machines and operate them remotely through **VNC**.

> ⚠️ Experimental: Windows programs run through an x86 emulator, so performance and compatibility vary from program to program.

### Features

- **32-bit and 64-bit programs**: each mode has its own isolated environment, so they never interfere with each other.
- **Automatic architecture detection**: with `arch_mode` set to `auto`, the add-on detects whether an EXE is 32-bit or 64-bit.
- **VNC remote desktop**: a desktop environment is built in; connect any VNC client to port 5900.
- **Locales and CJK fonts**: choose Japanese, Traditional Chinese, Simplified Chinese, Korean or English, with CJK font display handled automatically.
- **Config files next to the EXE**: the program's working directory is the folder containing the EXE, so config files stored beside it are read and saved normally.
- **Smaller HAOS backups**: the Wine environment lives in `/media` by default, which HAOS backups skip.

### Requirements

- Home Assistant OS on **aarch64 (ARM64)** hardware, such as a Raspberry Pi 4/5.
- 4 GB RAM or more is recommended (the x86 emulator and Wine are resource-hungry).

### Installation

1. In Home Assistant open **Settings → Add-ons → Add-on Store**.
2. Open the top-right menu → **Repositories** and add the repository that hosts this add-on: `https://github.com/lolimanko/hassio-addons`.
3. Refresh the page, find **Windows Runtime** and click **Install**.
4. Adjust the options on the **Configuration** tab, then start the add-on from the **Info** tab and check the **Log** tab.

### Options

| Option | Default | Description |
| --- | --- | --- |
| `app_exe` | `notepad.exe` | Windows program to launch. A bare file name is searched in `/share/windows-apps`, then `/media/windows-apps`. An absolute path such as `/media/apps/foo/foo.exe` also works. |
| `arch_mode` | `auto` | `auto` detects 32/64-bit; `32` or `64` forces a mode. |
| `locale` | `ja_JP.UTF-8` | One of `ja_JP.UTF-8`, `zh_TW.UTF-8`, `zh_CN.UTF-8`, `ko_KR.UTF-8`, `en_US.UTF-8`. Affects text encoding and font display. Restart the add-on after changing it. |
| `prefix_location` | `media` | `media`: Windows environment under `/media/windows_runtime/`, excluded from HAOS backups (default). `config`: stored in the add-on config directory and included in backups. Falls back to `config` if `/media` is not writable or does not support symlinks. |
| `vnc_password` | (empty) | VNC password. **An empty value falls back to `123456`, so please set your own.** |

### Directories

| Path | Purpose |
| --- | --- |
| `/share/windows-apps/` | Put your Windows programs here (default search location) |
| `/media/windows-apps/` | Put your Windows programs here (second search location, not in backups) |
| `/media/windows_runtime/wineprefix32`, `wineprefix64` | Windows environments when `prefix_location: media` |
| `/addon_configs/fdd0cf77_windows_runtime/wineprefix32`, `wineprefix64` | Windows environments when `prefix_location: config` |
| `/addon_configs/fdd0cf77_windows_runtime/logs/run.log` | Startup and runtime log |
| `/addon_configs/fdd0cf77_windows_runtime/vnc.pass` | VNC password file |

`/addon_configs/fdd0cf77_windows_runtime` is this add-on's config directory and can be accessed through Samba or SSH.

### Usage

1. Copy your program (with its config and resource files) into `/share/windows-apps/` or `/media/windows-apps/`.
2. Set `app_exe` in the add-on options, then save and start the add-on.
3. Connect a VNC client to `<HAOS IP>:5900` and enter the password to see the program.

### Architecture modes and the Windows environment

- An add-on instance runs one architecture mode at a time. To run 32-bit and 64-bit programs at the same time, install two copies of the add-on and set `arch_mode` in each.
- 32-bit and 64-bit modes each have their own Windows environment (`wineprefix32` / `wineprefix64`).
- To re-apply font settings, delete the `.fonts_done_*` files inside the environment folder and restart. To fully reset, stop the add-on and delete the whole `wineprefix32` or `wineprefix64` folder.

### About backups

HAOS backups of an add-on include `/addon_configs/fdd0cf77_windows_runtime` but not `/media`. A Windows environment is often several hundred MB, so keeping it in `/media` noticeably shrinks backups. The trade-offs:

- After restoring a backup, the Windows environment is recreated; software installed inside it and registry changes are not restored.
- Data that must be backed up should go in `/addon_configs/fdd0cf77_windows_runtime`, or set `prefix_location` to `config`.

### Troubleshooting

- **Download fails during installation**: make sure HAOS has network access and try again later.
- **Cannot connect over VNC or the log is empty**: check the add-on's **Log** tab and `/addon_configs/fdd0cf77_windows_runtime/logs/run.log`, and make sure the add-on is running and port 5900 is mapped.
- **First start is slow**: initializing the Windows environment is slow under emulation; the add-on waits up to 300 seconds (it still tries to start your program after a timeout), so please be patient.
- **Japanese (or other CJK) text shows as boxes**: make sure `locale` matches the program's language and restart after changing it.
- **Config file next to the EXE is not found**: the log lists the program folder's contents and whether it is writable; compare file name case and permissions.
- **`[BOX64] Error initializing native lib...` in the log**: the emulator could not find a native library and falls back to another version; this can normally be ignored.

### Known limitations

- aarch64 only.
- No audio output and no GPU acceleration.
- Performance depends on the emulator; heavy 3D programs or those needing extensive DirectX features may not work.
