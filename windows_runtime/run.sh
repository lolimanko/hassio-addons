#!/usr/bin/env bash
set -uo pipefail

# 最早期輸出：還沒導向日誌檔之前，直接寫到容器 stdout（Supervisor 日誌）
echo "[BOOT] run.sh 開始執行 $(date)"

CONFIG_DIR="/config"
OPTIONS_FILE="/data/options.json"
APP_DIR="/share/windows-apps"
LOG_DIR="${CONFIG_DIR}/logs"
VNC_PASSWORD_FILE="${CONFIG_DIR}/vnc.pass"
LOG_FILE="${LOG_DIR}/run.log"

MEDIA_DIR="/media"
MEDIA_BASE="${MEDIA_DIR}/windows_runtime"

# Wine prefix 預設位置（讀完設定後會依 prefix_location 選項重新決定）
WINE_PREFIX_32="${CONFIG_DIR}/wineprefix32"
WINE_PREFIX_64="${CONFIG_DIR}/wineprefix64"

mkdir -p "${CONFIG_DIR}" "${LOG_DIR}" "${APP_DIR}"

# 啟動前先整理舊日誌
if [[ -f "${LOG_FILE}" ]]; then
    tail -n 1000 "${LOG_FILE}" > "${LOG_FILE}.tmp" || true
    cat "${LOG_FILE}.tmp" > "${LOG_FILE}"
    rm -f "${LOG_FILE}.tmp"
fi

# 輸出同時寫入 Supervisor 日誌（stdout）與日誌檔
exec > >(tee -a "${LOG_FILE}") 2>&1

# 腳本結束（含異常中止）時一定留下紀錄
trap 'echo "[INFO] run.sh 結束，exit code=$?"' EXIT

echo "============================================================"
echo "[INFO] Container startup: $(date)"
echo "============================================================"

# 定時限制日誌行數
(
    while true; do
        sleep 60
        if [[ -f "${LOG_FILE}" ]]; then
            tail -n 1000 "${LOG_FILE}" > "${LOG_FILE}.tmp" 2>/dev/null || true
            if [[ -f "${LOG_FILE}.tmp" ]]; then
                cat "${LOG_FILE}.tmp" > "${LOG_FILE}"
                rm -f "${LOG_FILE}.tmp"
            fi
        fi
    done
) &
LOG_CLEANER_PID=$!

# ------------------------------------------------------------
# 讀取設定
# ------------------------------------------------------------
APP_EXE="test.exe"
VNC_PASSWORD="123456"
ARCH_MODE="auto"
LOCALE_OPT="ja_JP.UTF-8"
PREFIX_LOCATION="media"

if [[ -f "${OPTIONS_FILE}" ]]; then
    APP_EXE="$(jq -r '.app_exe // "test.exe"' "${OPTIONS_FILE}" 2>/dev/null || echo test.exe)"
    VNC_PASSWORD="$(jq -r '.vnc_password // "123456"' "${OPTIONS_FILE}" 2>/dev/null || echo 123456)"
    ARCH_MODE="$(jq -r '.arch_mode // "auto"' "${OPTIONS_FILE}" 2>/dev/null || echo auto)"
    LOCALE_OPT="$(jq -r '.locale // "ja_JP.UTF-8"' "${OPTIONS_FILE}" 2>/dev/null || echo ja_JP.UTF-8)"
    PREFIX_LOCATION="$(jq -r '.prefix_location // "media"' "${OPTIONS_FILE}" 2>/dev/null || echo media)"
else
    echo "[WARN] 找不到 ${OPTIONS_FILE}，使用預設設定"
fi

[[ -z "${APP_EXE}" || "${APP_EXE}" == "null" ]] && APP_EXE="test.exe"
[[ -z "${VNC_PASSWORD}" || "${VNC_PASSWORD}" == "null" ]] && VNC_PASSWORD="123456"
[[ -z "${ARCH_MODE}" || "${ARCH_MODE}" == "null" ]] && ARCH_MODE="auto"
[[ -z "${LOCALE_OPT}" || "${LOCALE_OPT}" == "null" ]] && LOCALE_OPT="ja_JP.UTF-8"

case "${LOCALE_OPT}" in
    ja_JP.UTF-8|zh_TW.UTF-8|zh_CN.UTF-8|ko_KR.UTF-8|en_US.UTF-8) ;;
    *)
        echo "[WARN] 不支援的 locale：${LOCALE_OPT}，改用 ja_JP.UTF-8"
        LOCALE_OPT="ja_JP.UTF-8"
        ;;
esac

[[ "${PREFIX_LOCATION}" != "config" ]] && PREFIX_LOCATION="media"

# ------------------------------------------------------------
# 決定 Wine prefix 存放位置
# media：放在 /media（不會被 HAOS 備份，備份檔較小）
# config：放在 add-on 設定目錄（會被備份）
# ------------------------------------------------------------
PREFIX_BASE="${CONFIG_DIR}"

if [[ "${PREFIX_LOCATION}" == "media" ]]; then
    if [[ ! -d "${MEDIA_DIR}" ]]; then
        echo "[WARN] 找不到 ${MEDIA_DIR}（add-on 是否已掛載 media？），Wine prefix 改放在 ${CONFIG_DIR}"
    elif ! mkdir -p "${MEDIA_BASE}" 2>/dev/null || [[ ! -w "${MEDIA_BASE}" ]]; then
        echo "[WARN] ${MEDIA_BASE} 不可寫入，Wine prefix 改放在 ${CONFIG_DIR}"
    elif ! ln -s test_target "${MEDIA_BASE}/.symlink_test" 2>/dev/null; then
        # Wine prefix 需要符號連結；部分網路儲存（CIFS/NFS）或 exFAT 不支援
        echo "[WARN] ${MEDIA_DIR} 所在儲存空間不支援符號連結，Wine prefix 改放在 ${CONFIG_DIR}"
    else
        rm -f "${MEDIA_BASE}/.symlink_test"
        PREFIX_BASE="${MEDIA_BASE}"
    fi
fi

WINE_PREFIX_32="${PREFIX_BASE}/wineprefix32"
WINE_PREFIX_64="${PREFIX_BASE}/wineprefix64"
echo "[INFO] Wine prefix 位置：${PREFIX_BASE}（選項：${PREFIX_LOCATION}）"

# 若 prefix 原本在 /config、現在要放 /media，且 /media 尚無同名 prefix，就搬移過去
if [[ "${PREFIX_BASE}" != "${CONFIG_DIR}" ]]; then
    for n in wineprefix32 wineprefix64; do
        if [[ -d "${CONFIG_DIR}/${n}" && ! -e "${PREFIX_BASE}/${n}" ]]; then
            echo "[INFO] 搬移既有 ${n}：${CONFIG_DIR} → ${PREFIX_BASE}（可能需要一些時間）"
            if mv "${CONFIG_DIR}/${n}" "${PREFIX_BASE}/${n}"; then
                echo "[OK] ${n} 已搬移"
            else
                echo "[ERROR] ${n} 搬移失敗，請手動檢查 ${CONFIG_DIR}/${n}"
            fi
        fi
    done
fi

# ------------------------------------------------------------
# 決定 EXE 路徑
# 1. 絕對路徑（例如 /media/xxx/app.exe）直接使用
# 2. 相對路徑先找 /share/windows-apps，找不到再找 /media/windows-apps
# ------------------------------------------------------------
mkdir -p "${MEDIA_DIR}/windows-apps" 2>/dev/null || true

if [[ "${APP_EXE}" = /* ]]; then
    EXE_PATH="${APP_EXE}"
elif [[ -f "${APP_DIR}/${APP_EXE}" ]]; then
    EXE_PATH="${APP_DIR}/${APP_EXE}"
elif [[ -f "${MEDIA_DIR}/windows-apps/${APP_EXE}" ]]; then
    EXE_PATH="${MEDIA_DIR}/windows-apps/${APP_EXE}"
else
    EXE_PATH="${APP_DIR}/${APP_EXE}"
fi

echo "[INFO] app_exe=${APP_EXE}, arch_mode=${ARCH_MODE}, locale=${LOCALE_OPT}, prefix_location=${PREFIX_LOCATION}"

# ------------------------------------------------------------
# 判斷 EXE 位元數（讀取 PE header 的 Machine 欄位）
# ------------------------------------------------------------
detect_pe_arch() {
    local f="$1" magic off machine
    [[ -r "${f}" ]] || { echo unknown; return; }

    magic="$(od -An -c -N 2 "${f}" 2>/dev/null | tr -d ' ')"
    [[ "${magic}" == "MZ" ]] || { echo unknown; return; }

    off="$(od -An -t u4 -j 60 -N 4 "${f}" 2>/dev/null | tr -d ' ')"
    [[ -n "${off}" ]] || { echo unknown; return; }

    machine="$(od -An -t x2 -j $((off + 4)) -N 2 "${f}" 2>/dev/null | tr -d ' ')"
    case "${machine}" in
        014c) echo 32 ;;
        8664) echo 64 ;;
        *)    echo unknown ;;
    esac
}

case "${ARCH_MODE}" in
    32|64)
        TARGET_ARCH="${ARCH_MODE}"
        echo "[INFO] 手動指定模式：${TARGET_ARCH} 位元"
        DETECTED="$(detect_pe_arch "${EXE_PATH}")"
        if [[ "${DETECTED}" != "unknown" && "${DETECTED}" != "${TARGET_ARCH}" ]]; then
            echo "[WARN] 設定為 ${TARGET_ARCH} 位元，但 EXE 偵測為 ${DETECTED} 位元"
        fi
        ;;
    *)
        DETECTED="$(detect_pe_arch "${EXE_PATH}")"
        if [[ "${DETECTED}" == "unknown" ]]; then
            TARGET_ARCH="32"
            echo "[INFO] 無法判斷 EXE 位元數，預設使用 32 位元"
        else
            TARGET_ARCH="${DETECTED}"
            echo "[INFO] 自動偵測 EXE 為 ${TARGET_ARCH} 位元"
        fi
        ;;
esac

# ------------------------------------------------------------
# Wine / Box 環境（依位元數切換）
# ------------------------------------------------------------
export DISPLAY=":0"
export PATH="/usr/local/bin:/opt/wine/usr/bin:/usr/bin:/bin"
# 語系（由 add-on 設定的 locale 選項決定，會影響 Wine 的 ANSI 碼頁）
export LANG="${LOCALE_OPT}"
export LC_ALL="${LOCALE_OPT}"
# 預設關閉 Wine 除錯輸出；需要時在容器內 export WINEDEBUG="+loaddll,+module"
export WINEDEBUG="${WINEDEBUG:--all}"

# Box86 (32-bit)
export BOX86_LD_LIBRARY_PATH="/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:/opt/wine/usr/lib/i386-linux-gnu:/opt/wine/usr/lib/i386-linux-gnu/wine/i386-unix:/opt/wine/usr/lib/wine"
export BOX86_PATH="/opt/wine/usr/lib/wine"

# Box64 (64-bit)
export BOX64_LD_LIBRARY_PATH="/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/opt/wine/usr/lib/x86_64-linux-gnu:/opt/wine/usr/lib/x86_64-linux-gnu/wine/x86_64-unix:/opt/wine/usr/lib/wine"
export BOX64_PATH="/opt/wine/usr/lib/wine"

if [[ "${TARGET_ARCH}" == "64" ]]; then
    export WINEARCH="win64"
    export WINEPREFIX="${WINE_PREFIX_64}"
    export WINEDLLPATH="/usr/lib/x86_64-linux-gnu/wine/x86_64-windows:/usr/lib/x86_64-linux-gnu/wine/x86_64-unix"
    export WINESERVER="/opt/wine/usr/lib/wine/wineserver64"
    WINE_CMD="wine64"
    ZLIB_DLL="/opt/wine/usr/lib/x86_64-linux-gnu/wine/x86_64-windows/zlib1.dll"
else
    export WINEARCH="win32"
    export WINEPREFIX="${WINE_PREFIX_32}"
    export WINEDLLPATH="/usr/lib/i386-linux-gnu/wine/i386-windows:/usr/lib/i386-linux-gnu/wine/i386-unix"
    export WINESERVER="/opt/wine/usr/lib/wine/wineserver32"
    WINE_CMD="wine"
    ZLIB_DLL="/opt/wine/usr/lib/i386-linux-gnu/wine/i386-windows/zlib1.dll"
fi

WINE_PREFIX="${WINEPREFIX}"
SYSTEM32_DIR="${WINE_PREFIX}/drive_c/windows/system32"

# ------------------------------------------------------------
# 指令檢查
# ------------------------------------------------------------
echo "============================================================"
echo "[INFO] 檢查執行環境（模式：${TARGET_ARCH} 位元）"
echo "============================================================"

for cmd in Xvfb x11vnc fluxbox wine wine64 box86 box64 jq fc-list; do
    if command -v "${cmd}" >/dev/null 2>&1; then
        echo "[OK] ${cmd}: $(command -v "${cmd}")"
    else
        echo "[ERROR] 找不到指令：${cmd}"
    fi
done

# 加 timeout，避免 Box 版本檢查卡住整個啟動流程
echo "[INFO] Box86 version:"
timeout 10 box86 --version || echo "[WARN] box86 --version 失敗或逾時 (exit=$?)"
echo "[INFO] Box64 version:"
timeout 10 box64 --version || echo "[WARN] box64 --version 失敗或逾時 (exit=$?)"

echo "[INFO] LANG=${LANG}"
if locale -a 2>/dev/null | grep -qix "${LOCALE_OPT//UTF-8/utf8}"; then
    echo "[OK] locale ${LOCALE_OPT} 可用"
else
    echo "[WARN] 系統找不到 locale ${LOCALE_OPT}，Wine 可能退回預設語系"
fi
case "${LOCALE_OPT}" in
    ja_JP*) FC_LANG="ja" ;;
    zh_TW*) FC_LANG="zh-tw" ;;
    zh_CN*) FC_LANG="zh-cn" ;;
    ko_KR*) FC_LANG="ko" ;;
    *)      FC_LANG="" ;;
esac
if [[ -n "${FC_LANG}" ]]; then
    echo "[INFO] 系統 ${FC_LANG} 字型："
    fc-list ":lang=${FC_LANG}" family 2>/dev/null | sort -u | head -n 10 || true
fi

# ------------------------------------------------------------
# Xvfb
# ------------------------------------------------------------
echo "============================================================"
echo "[INFO] 啟動 Xvfb"
echo "============================================================"

Xvfb "${DISPLAY}" -screen 0 1280x800x24 -ac -noreset &
XVFB_PID=$!
sleep 2

if kill -0 "${XVFB_PID}" 2>/dev/null; then
    echo "[OK] Xvfb PID=${XVFB_PID}"
else
    echo "[ERROR] Xvfb 啟動失敗"
fi

if command -v dbus-launch >/dev/null 2>&1; then
    DBUS_ENV="$(timeout 10 dbus-launch --sh-syntax 2>/dev/null)" && eval "${DBUS_ENV}" \
        || echo "[WARN] dbus-launch 失敗或逾時"
fi

# ------------------------------------------------------------
# Fluxbox
# ------------------------------------------------------------
echo "============================================================"
echo "[INFO] 啟動 Fluxbox"
echo "============================================================"

fluxbox &
FLUXBOX_PID=$!
sleep 1

if kill -0 "${FLUXBOX_PID}" 2>/dev/null; then
    echo "[OK] Fluxbox PID=${FLUXBOX_PID}"
else
    echo "[WARN] Fluxbox 可能未正常啟動"
fi

# ------------------------------------------------------------
# VNC
# ------------------------------------------------------------
echo "============================================================"
echo "[INFO] 啟動 VNC"
echo "============================================================"

if [[ -n "${VNC_PASSWORD}" ]] && command -v x11vnc >/dev/null 2>&1; then
    x11vnc -storepasswd "${VNC_PASSWORD}" "${VNC_PASSWORD_FILE}" >/dev/null 2>&1 || true
    chmod 600 "${VNC_PASSWORD_FILE}" 2>/dev/null || true

    x11vnc \
        -display "${DISPLAY}" \
        -rfbauth "${VNC_PASSWORD_FILE}" \
        -forever -shared \
        -rfbport 5900 -listen 0.0.0.0 \
        -noxdamage &
else
    x11vnc \
        -display "${DISPLAY}" \
        -nopw \
        -forever -shared \
        -rfbport 5900 -listen 0.0.0.0 \
        -noxdamage &
fi
VNC_PID=$!
sleep 2

if kill -0 "${VNC_PID}" 2>/dev/null; then
    echo "[OK] VNC PID=${VNC_PID}, port=5900"
else
    echo "[ERROR] VNC 啟動失敗"
fi

# ------------------------------------------------------------
# 檢查 Wine DLL
# ------------------------------------------------------------
echo "============================================================"
echo "[INFO] 檢查 Wine DLL"
echo "============================================================"

mkdir -p "${SYSTEM32_DIR}"

if [[ -f "${ZLIB_DLL}" ]]; then
    echo "[OK] 找到 zlib1.dll"
    file "${ZLIB_DLL}" || true
    cp -f "${ZLIB_DLL}" "${SYSTEM32_DIR}/zlib1.dll"
    echo "[OK] zlib1.dll 已複製到 ${SYSTEM32_DIR}"
else
    echo "[ERROR] 找不到 zlib1.dll：${ZLIB_DLL}"
fi

echo "[INFO] WINEARCH=${WINEARCH}"
echo "[INFO] WINEDLLPATH=${WINEDLLPATH}"
echo "[INFO] WINESERVER=${WINESERVER}"
echo "[INFO] WINEPREFIX=${WINEPREFIX}"

# ------------------------------------------------------------
# Wine 初始化（加逾時，避免無限卡住）
# ------------------------------------------------------------
echo "============================================================"
echo "[INFO] Wine Prefix 初始化"
echo "============================================================"

mkdir -p "${WINE_PREFIX}"

if [[ -f "${WINE_PREFIX}/system.reg" ]]; then
    echo "[INFO] 偵測到既有 Wine Prefix，保留原有設定"
else
    echo "[INFO] 尚未建立 Wine Prefix，準備首次初始化（可能需要數分鐘）"
fi

timeout 300 "${WINE_CMD}" wineboot.exe -u
WINEBOOT_STATUS=$?

echo "[INFO] wineboot exit code=${WINEBOOT_STATUS}"

if [[ "${WINEBOOT_STATUS}" -eq 0 ]]; then
    echo "[OK] Wine 初始化成功"
elif [[ "${WINEBOOT_STATUS}" -eq 124 ]]; then
    echo "[ERROR] wineboot 逾時（300 秒），仍會嘗試啟動 Windows 程式"
else
    echo "[WARN] wineboot 回傳非 0，仍會嘗試啟動 Windows 程式"
fi

# ------------------------------------------------------------
# CJK 字型替換（依 locale；每個 prefix + 語系只做一次）
# 想重新套用：刪除 ${WINE_PREFIX}/.fonts_done_* 後重啟
# ------------------------------------------------------------
SANS_NAMES=(); SERIF_NAMES=(); WIDE_SANS=(); WIDE_SERIF=()
FONT_TAG=""

case "${LOCALE_OPT}" in
    ja_JP.UTF-8)
        FONT_TAG="ja"
        SANS="Noto Sans CJK JP"; SERIF="Noto Serif CJK JP"
        SANS_NAMES=("MS Shell Dlg" "MS Shell Dlg 2" "MS Gothic" "MS PGothic" "MS UI Gothic" "Meiryo" "Meiryo UI" "Yu Gothic" "Yu Gothic UI")
        SERIF_NAMES=("MS Mincho" "MS PMincho" "Yu Mincho")
        WIDE_SANS=("ＭＳ ゴシック" "ＭＳ Ｐゴシック")
        WIDE_SERIF=("ＭＳ 明朝" "ＭＳ Ｐ明朝")
        ;;
    zh_TW.UTF-8)
        FONT_TAG="zhtw"
        SANS="Noto Sans CJK TC"; SERIF="Noto Serif CJK TC"
        SANS_NAMES=("MS Shell Dlg" "MS Shell Dlg 2" "Microsoft JhengHei" "Microsoft JhengHei UI")
        SERIF_NAMES=("PMingLiU" "MingLiU" "PMingLiU-ExtB" "MingLiU-ExtB")
        WIDE_SANS=("微軟正黑體")
        WIDE_SERIF=("新細明體" "細明體")
        ;;
    zh_CN.UTF-8)
        FONT_TAG="zhcn"
        SANS="Noto Sans CJK SC"; SERIF="Noto Serif CJK SC"
        SANS_NAMES=("MS Shell Dlg" "MS Shell Dlg 2" "Microsoft YaHei" "Microsoft YaHei UI" "SimHei")
        SERIF_NAMES=("SimSun" "NSimSun")
        WIDE_SANS=("微软雅黑" "黑体")
        WIDE_SERIF=("宋体" "新宋体")
        ;;
    ko_KR.UTF-8)
        FONT_TAG="ko"
        SANS="Noto Sans CJK KR"; SERIF="Noto Serif CJK KR"
        SANS_NAMES=("MS Shell Dlg" "MS Shell Dlg 2" "Malgun Gothic" "Gulim" "GulimChe" "Dotum" "DotumChe")
        SERIF_NAMES=("Batang" "BatangChe" "Gungsuh")
        WIDE_SANS=("맑은 고딕" "굴림" "돋움")
        WIDE_SERIF=("바탕" "궁서")
        ;;
    *)
        echo "[INFO] locale=${LOCALE_OPT}，不需要 CJK 字型替換"
        ;;
esac

if [[ -n "${FONT_TAG}" ]]; then
    FONT_MARK="${WINE_PREFIX}/.fonts_done_${FONT_TAG}"

    if [[ ! -f "${FONT_MARK}" ]]; then
        echo "============================================================"
        echo "[INFO] 設定 CJK 字型替換（${LOCALE_OPT}）"
        echo "============================================================"

        if ! fc-list | grep -qi "${SANS}"; then
            echo "[WARN] 系統找不到字型 ${SANS}，字型替換可能無效"
        fi

        FONT_REG="/tmp/cjk_fonts.reg"
        {
            echo "Windows Registry Editor Version 5.00"
            echo
            echo '[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes]'
            for n in "${SANS_NAMES[@]}";  do echo "\"${n}\"=\"${SANS}\"";  done
            for n in "${SERIF_NAMES[@]}"; do echo "\"${n}\"=\"${SERIF}\""; done
            echo
            echo '[HKEY_CURRENT_USER\Software\Wine\Fonts\Replacements]'
            for n in "${SANS_NAMES[@]}"; do
                [[ "${n}" == "MS Shell Dlg"* ]] && continue
                echo "\"${n}\"=\"${SANS}\""
            done
            for n in "${SERIF_NAMES[@]}"; do echo "\"${n}\"=\"${SERIF}\""; done
        } > "${FONT_REG}"

        if timeout 120 "${WINE_CMD}" regedit /S "${FONT_REG}"; then
            # 非 ASCII 的字型名稱（部分程式會直接使用在地語系名稱）
            for n in "${WIDE_SANS[@]}"; do
                timeout 60 "${WINE_CMD}" reg add \
                    'HKCU\Software\Wine\Fonts\Replacements' \
                    /v "${n}" /d "${SANS}" /f || true
            done
            for n in "${WIDE_SERIF[@]}"; do
                timeout 60 "${WINE_CMD}" reg add \
                    'HKCU\Software\Wine\Fonts\Replacements' \
                    /v "${n}" /d "${SERIF}" /f || true
            done
            touch "${FONT_MARK}"
            echo "[OK] 字型替換已寫入登錄檔"
        else
            echo "[WARN] 字型替換寫入失敗，下次啟動會重試"
        fi
        rm -f "${FONT_REG}"
    else
        echo "[INFO] ${LOCALE_OPT} 字型替換先前已設定，略過"
    fi
fi

# ------------------------------------------------------------
# 啟動 Windows EXE
# ------------------------------------------------------------
echo "============================================================"
echo "[INFO] Windows 程式啟動（${TARGET_ARCH} 位元）"
echo "============================================================"

if [[ -f "${EXE_PATH}" ]]; then
    echo "[OK] 找到程式：${EXE_PATH}"

    # 工作目錄必須是 EXE 所在目錄，否則程式以相對路徑讀取的設定檔會找不到
    EXE_DIR="$(dirname "${EXE_PATH}")"
    echo "[INFO] 工作目錄：${EXE_DIR}"

    if [[ -w "${EXE_DIR}" ]]; then
        echo "[OK] 工作目錄可寫入"
    else
        echo "[WARN] 工作目錄不可寫入，程式將無法儲存設定檔"
    fi

    echo "[INFO] 工作目錄內容（前 30 項）："
    ls -la "${EXE_DIR}" 2>/dev/null | head -n 30 || true

    # 在子 shell 中 cd 後再 exec，Wine 會以該目錄作為目前目錄 (Z:\share\windows-apps\...)
    (
        cd "${EXE_DIR}" || exit 1
        exec "${WINE_CMD}" "${EXE_PATH}"
    ) &
    WINE_PID=$!
    echo "[INFO] Windows 程式 PID=${WINE_PID}"
else
    echo "[WARN] 找不到 Windows EXE：${EXE_PATH}"
    echo "[INFO] 請確認程式放在 ${APP_DIR} 或 ${MEDIA_DIR}/windows-apps，或在 app_exe 填完整路徑"
fi

# ------------------------------------------------------------
# 保持容器運作，並監控關鍵程序
# ------------------------------------------------------------
echo "============================================================"
echo "[INFO] 除錯模式：容器保持運作"
echo "[INFO] 模式：${TARGET_ARCH} 位元"
echo "[INFO] VNC port：5900"
echo "[INFO] 日誌：${LOG_FILE}"
echo "[INFO] Wine Prefix：${WINE_PREFIX}"
echo "============================================================"

while true; do
    sleep 60
    kill -0 "${XVFB_PID}" 2>/dev/null || echo "[ERROR] $(date +%T) Xvfb 已結束"
    kill -0 "${VNC_PID}"  2>/dev/null || echo "[ERROR] $(date +%T) x11vnc 已結束"
done
