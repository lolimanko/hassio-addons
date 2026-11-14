FROM debian:bookworm-slim

# 1. 基本工具及編譯環境
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates git cmake build-essential \
        python3 python3-minimal python3-dev \
        gcc-arm-linux-gnueabihf \
        g++-arm-linux-gnueabihf \
        libc6-dev-armhf-cross \
        pkg-config file wget curl xz-utils unzip dpkg jq \
        libz-mingw-w64 \
    && rm -rf /var/lib/apt/lists/*

# 2. 啟用 ARMHF、i386、amd64 多架構
RUN dpkg --add-architecture armhf && \
    dpkg --add-architecture i386 && \
    dpkg --add-architecture amd64 && \
    apt-get update

# 3. ARMHF 相依套件 (Box86 使用)
RUN apt-get install -y --no-install-recommends \
        libc6:armhf \
        libstdc++6:armhf \
        libgcc-s1:armhf \
        libx11-6:armhf \
        libxext6:armhf \
        libxrender1:armhf \
        libxfixes3:armhf \
        libxi6:armhf \
        libxcursor1:armhf \
        libxrandr2:armhf \
        libxinerama1:armhf \
        libxcomposite1:armhf \
        libasound2:armhf \
        libfreetype6:armhf \
        libfontconfig1:armhf \
        libglib2.0-0:armhf \
        libgnutls30:armhf \
        libdbus-1-3:armhf \
        libudev1:armhf \
        libusb-1.0-0:armhf \
    && rm -rf /var/lib/apt/lists/*

# 4. i386 Wine / Box86 相依套件
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libc6:i386 \
        libgcc-s1:i386 \
        libstdc++6:i386 \
        libz1:i386 \
        libbsd0:i386 \
        libgnutls30:i386 \
        libdbus-1-3:i386 \
        libgssapi-krb5-2:i386 \
        libkrb5-3:i386 \
        libkrb5support0:i386 \
        libk5crypto3:i386 \
        libcom-err2:i386 \
        libkeyutils1:i386 \
        libavahi-client3:i386 \
        libavahi-common3:i386 \
        libcups2:i386 \
        libasound2:i386 \
    && rm -rf /var/lib/apt/lists/*

# 4b. amd64 Wine / Box64 相依套件
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libc6:amd64 \
        libstdc++6:amd64 \
        libgcc-s1:amd64 \
        libz1:amd64 \
        libbsd0:amd64 \
        libx11-6:amd64 \
        libxext6:amd64 \
        libxrender1:amd64 \
        libxfixes3:amd64 \
        libxi6:amd64 \
        libxcursor1:amd64 \
        libxrandr2:amd64 \
        libxinerama1:amd64 \
        libxcomposite1:amd64 \
        libasound2:amd64 \
        libfreetype6:amd64 \
        libfontconfig1:amd64 \
        libglib2.0-0:amd64 \
        libgnutls30:amd64 \
        libdbus-1-3:amd64 \
        libudev1:amd64 \
        libusb-1.0-0:amd64 \
        libgssapi-krb5-2:amd64 \
        libkrb5-3:amd64 \
        libk5crypto3:amd64 \
        libcom-err2:amd64 \
        libkeyutils1:amd64 \
        libcups2:amd64 \
        libavahi-client3:amd64 \
        libavahi-common3:amd64 \
    && rm -rf /var/lib/apt/lists/*

# 5. X11 / VNC
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xvfb x11vnc xauth x11-utils \
        xterm fluxbox dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# 5b. CJK 字型、locale 與字型函式庫
#     - fonts-noto-cjk / fonts-takao: 日文字型
#     - locales: 產生 ja_JP / zh_TW / zh_CN / ko_KR / en_US 的 UTF-8 locale，
#       實際使用哪個由 add-on 設定的 locale 選項決定（run.sh 內切換）
#     - libfreetype6:i386 / libfontconfig1:i386: 32 位元 Wine 讀取字型所需
#     - libfreetype6 / libfontconfig1 / libxcursor1 / libusb-1.0-0 (arm64 原生):
#       供 Box64 使用原生函式庫，並消除相關警告
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        fontconfig \
        fonts-noto-cjk \
        fonts-takao-gothic \
        fonts-takao-mincho \
        locales \
        libfreetype6 libfontconfig1 \
        libfreetype6:i386 libfontconfig1:i386 \
        libxcursor1 libusb-1.0-0 \
    && for l in ja_JP zh_TW zh_CN ko_KR en_US; do \
           sed -i "s/^# *\(${l}.UTF-8 UTF-8\)/\1/" /etc/locale.gen; \
       done \
    && locale-gen \
    && fc-cache -f \
    && fc-list :lang=ja family | sort -u \
    && rm -rf /var/lib/apt/lists/*

# 6. 編譯 Box86
RUN git clone --depth 1 \
        https://github.com/ptitSeb/box86.git /tmp/box86 && \
    mkdir -p /tmp/box86/build && \
    cd /tmp/box86/build && \
    /usr/bin/python3 --version && \
    cmake .. \
        -DRPI4ARM64=1 \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DPython3_EXECUTABLE=/usr/bin/python3 && \
    make -j2 && \
    make install && \
    rm -rf /tmp/box86

# 6b. 編譯 Box64 (原生 arm64，不需交叉編譯器)
RUN git clone --depth 1 \
        https://github.com/ptitSeb/box64.git /tmp/box64 && \
    mkdir -p /tmp/box64/build && \
    cd /tmp/box64/build && \
    cmake .. \
        -DARM64=1 \
        -DARM_DYNAREC=ON \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DPython3_EXECUTABLE=/usr/bin/python3 && \
    make -j2 && \
    make install && \
    rm -rf /tmp/box64

# 7. 建立 Wine 目錄
RUN mkdir -p /opt/wine /tmp/wine

# 8. 複製 Wine 套件 (i386 + amd64，版本需一致)
COPY libwine_8.0~repack-4_i386.deb /tmp/wine/
COPY wine32-preloader_8.0~repack-4_i386.deb /tmp/wine/
COPY wine32_8.0~repack-4_i386.deb /tmp/wine/
COPY libwine_8.0~repack-4_amd64.deb /tmp/wine/
COPY wine64-preloader_8.0~repack-4_amd64.deb /tmp/wine/
COPY wine64_8.0~repack-4_amd64.deb /tmp/wine/
COPY wine_8.0~repack-4_all.deb /tmp/wine/

# 9. 解壓縮 Wine 套件
RUN dpkg-deb -x /tmp/wine/libwine_8.0~repack-4_i386.deb /opt/wine && \
    dpkg-deb -x /tmp/wine/wine32-preloader_8.0~repack-4_i386.deb /opt/wine && \
    dpkg-deb -x /tmp/wine/wine32_8.0~repack-4_i386.deb /opt/wine && \
    dpkg-deb -x /tmp/wine/libwine_8.0~repack-4_amd64.deb /opt/wine && \
    dpkg-deb -x /tmp/wine/wine64-preloader_8.0~repack-4_amd64.deb /opt/wine && \
    dpkg-deb -x /tmp/wine/wine64_8.0~repack-4_amd64.deb /opt/wine && \
    dpkg-deb -x /tmp/wine/wine_8.0~repack-4_all.deb /opt/wine && \
    rm -rf /tmp/wine

# 10. 安裝 32 位元 Windows zlib DLL
RUN mkdir -p /opt/wine/usr/lib/i386-linux-gnu/wine/i386-windows && \
    cp /usr/i686-w64-mingw32/lib/zlib1.dll \
       /opt/wine/usr/lib/i386-linux-gnu/wine/i386-windows/zlib1.dll && \
    file /opt/wine/usr/lib/i386-linux-gnu/wine/i386-windows/zlib1.dll

# 10b. 安裝 64 位元 Windows zlib DLL
RUN mkdir -p /opt/wine/usr/lib/x86_64-linux-gnu/wine/x86_64-windows && \
    cp /usr/x86_64-w64-mingw32/lib/zlib1.dll \
       /opt/wine/usr/lib/x86_64-linux-gnu/wine/x86_64-windows/zlib1.dll && \
    file /opt/wine/usr/lib/x86_64-linux-gnu/wine/x86_64-windows/zlib1.dll

# 11. 建立 Debian Wine 所需路徑 (32 位元 + 共用)
RUN mkdir -p /usr/lib /usr/share /usr/lib/i386-linux-gnu && \
    ln -s /opt/wine/usr/lib/wine /usr/lib/wine && \
    ln -s /opt/wine/usr/share/wine /usr/share/wine && \
    ln -s /opt/wine/usr/lib/i386-linux-gnu/wine \
          /usr/lib/i386-linux-gnu/wine

# 11b. 建立 amd64 Wine 路徑
RUN mkdir -p /usr/lib/x86_64-linux-gnu && \
    ln -s /opt/wine/usr/lib/x86_64-linux-gnu/wine \
          /usr/lib/x86_64-linux-gnu/wine

# 12. Wine 主程式 Box86 wrapper (32 位元)
RUN printf '%s\n' \
    '#!/bin/sh' \
    'exec /usr/local/bin/box86 /opt/wine/usr/lib/wine/wine "$@"' \
    > /usr/local/bin/wine && \
    chmod +x /usr/local/bin/wine

# 12b. Wine64 主程式 Box64 wrapper (64 位元)
RUN printf '%s\n' \
    '#!/bin/sh' \
    'exec /usr/local/bin/box64 /opt/wine/usr/lib/wine/wine64 "$@"' \
    > /usr/local/bin/wine64 && \
    chmod +x /usr/local/bin/wine64

# 13. Wine stable 啟動器
RUN printf '%s\n' \
    '#!/bin/sh' \
    'export PATH="/usr/local/bin:/opt/wine/usr/bin:/usr/bin:/bin"' \
    'exec /usr/local/bin/wine "$@"' \
    > /usr/local/bin/wine-stable && \
    chmod +x /usr/local/bin/wine-stable

# 14. Wineboot 啟動器 (32 位元)
RUN printf '%s\n' \
    '#!/bin/sh' \
    'export PATH="/usr/local/bin:/opt/wine/usr/bin:/usr/bin:/bin"' \
    'exec /usr/local/bin/wine-stable wineboot.exe "$@"' \
    > /usr/local/bin/wineboot && \
    chmod +x /usr/local/bin/wineboot

# 14b. Wineboot64 啟動器 (64 位元)
RUN printf '%s\n' \
    '#!/bin/sh' \
    'export PATH="/usr/local/bin:/opt/wine/usr/bin:/usr/bin:/bin"' \
    'exec /usr/local/bin/wine64 wineboot.exe "$@"' \
    > /usr/local/bin/wineboot64 && \
    chmod +x /usr/local/bin/wineboot64

# 15. Wineserver32 Box86 wrapper
RUN if [ -f /opt/wine/usr/lib/wine/wineserver32 ]; then \
        mv /opt/wine/usr/lib/wine/wineserver32 \
           /opt/wine/usr/lib/wine/wineserver32.bin; \
    fi && \
    printf '%s\n' \
    '#!/bin/sh' \
    'exec /usr/local/bin/box86 /opt/wine/usr/lib/wine/wineserver32.bin "$@"' \
    > /opt/wine/usr/lib/wine/wineserver32 && \
    chmod +x /opt/wine/usr/lib/wine/wineserver32

# 15b. Wineserver64 Box64 wrapper
RUN if [ -f /opt/wine/usr/lib/wine/wineserver64 ]; then \
        mv /opt/wine/usr/lib/wine/wineserver64 \
           /opt/wine/usr/lib/wine/wineserver64.bin; \
    fi && \
    printf '%s\n' \
    '#!/bin/sh' \
    'exec /usr/local/bin/box64 /opt/wine/usr/lib/wine/wineserver64.bin "$@"' \
    > /opt/wine/usr/lib/wine/wineserver64 && \
    chmod +x /opt/wine/usr/lib/wine/wineserver64

# 16. 檢查 32 位元 Wine 檔案
RUN set -e; \
    test -f /opt/wine/usr/lib/wine/wine; \
    test -f /opt/wine/usr/lib/wine/wineserver32.bin; \
    test -f /opt/wine/usr/lib/i386-linux-gnu/wine/i386-windows/kernel32.dll; \
    test -f /opt/wine/usr/lib/i386-linux-gnu/wine/i386-unix/ntdll.so; \
    test -f /opt/wine/usr/bin/wineboot-stable; \
    test -f /opt/wine/usr/bin/wine-stable; \
    test -f /opt/wine/usr/lib/i386-linux-gnu/wine/i386-windows/zlib1.dll

# 16b. 檢查 64 位元 Wine 檔案
RUN set -e; \
    test -f /opt/wine/usr/lib/wine/wine64; \
    test -f /opt/wine/usr/lib/wine/wineserver64.bin; \
    test -f /opt/wine/usr/lib/x86_64-linux-gnu/wine/x86_64-windows/kernel32.dll; \
    test -f /opt/wine/usr/lib/x86_64-linux-gnu/wine/x86_64-unix/ntdll.so; \
    test -f /opt/wine/usr/lib/x86_64-linux-gnu/wine/x86_64-windows/zlib1.dll

# 17. 環境變數
#     WINEARCH / WINEPREFIX / WINEDLLPATH / WINESERVER 由 run.sh 依 32/64 位元模式設定
#     LANG / LC_ALL 這裡只是預設值，run.sh 會依 add-on 的 locale 選項覆蓋
ENV DISPLAY=:0
ENV LANG=ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8
ENV BOX86_LD_LIBRARY_PATH=/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:/opt/wine/usr/lib/i386-linux-gnu:/opt/wine/usr/lib/i386-linux-gnu/wine/i386-unix:/opt/wine/usr/lib/wine
ENV BOX86_PATH=/opt/wine/usr/lib/wine
ENV BOX64_LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/opt/wine/usr/lib/x86_64-linux-gnu:/opt/wine/usr/lib/x86_64-linux-gnu/wine/x86_64-unix:/opt/wine/usr/lib/wine
ENV BOX64_PATH=/opt/wine/usr/lib/wine
ENV PATH=/usr/local/bin:/opt/wine/usr/bin:/usr/bin:/bin

# 18. 建立目錄
RUN mkdir -p /data /config /share /app /root/.vnc

# 19. 複製啟動腳本 (順便移除可能的 Windows CRLF 換行)
COPY run.sh /app/run.sh
RUN sed -i 's/\r$//' /app/run.sh && chmod +x /app/run.sh

WORKDIR /app

CMD ["/app/run.sh"]
