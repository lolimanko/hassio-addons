# ---------- Stage 1: 取得原始碼並編譯 Web UI ----------
FROM node:20-bookworm-slim AS ui
# 建議釘選成穩定的 release tag，例如 --build-arg TRIBLER_REF=v8.0.7
ARG TRIBLER_REF=main
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --recursive --depth 1 --branch "${TRIBLER_REF}" \
      https://github.com/Tribler/tribler /tribler
WORKDIR /tribler/src/tribler/ui
RUN npm install && npm run build
RUN rm -rf node_modules \
 && find /tribler -name .git -prune -exec rm -rf {} +

# ---------- Stage 2: 執行環境（amd64 / aarch64 皆可）----------
FROM python:3.12-slim-trixie
ENV LANG=C.UTF-8 PYTHONUNBUFFERED=1

COPY --from=ui /tribler /tribler

# ipv8-rust-tunnels 的 aarch64 預編譯 wheel 連結不完整（缺 ffmpeg/vpx 等符號），
# 所以用 Rust 從原始碼編譯。它依賴 ffmpeg-sys-next，需要 FFmpeg 開發套件 + clang(bindgen)。
# FFmpeg 的函式庫是執行期也要用的，所以不 purge；只移除 Rust 工具鏈與 apt 快取。
# 注意：在 ARM 板子上第一次建置會很久（可能 10~30 分鐘以上）。
ENV PATH="/root/.cargo/bin:${PATH}"

# 步驟 1：系統套件
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libsodium23 build-essential pkg-config curl ca-certificates \
      libssl-dev libffi-dev clang libclang-dev \
      libavcodec-dev libavformat-dev libavutil-dev libavfilter-dev \
      libavdevice-dev libswscale-dev libswresample-dev \
 && rm -rf /var/lib/apt/lists/*

# 步驟 2：Rust 工具鏈
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal \
 && rustc --version && cargo --version

# 步驟 3a：挑版本 + 從原始碼編譯 ipv8-rust-tunnels 成 wheel
# - requirements.txt 沒有限制 ipv8-rust-tunnels 版本，最新版(0.1.61)已改 API（移除 EndpointNotOpenError），
#   Tribler 這份程式碼還在用舊 API，所以自動挑出「最新且確實匯出舊 API」的版本。
# - 編譯：tokio::task::Builder 需要 --cfg tokio_unstable（上游靠 .cargo/config.toml，但 sdist 沒附）。
# - 獨立成一層：後面步驟失敗時，不必重新編譯（約數分鐘到十幾分鐘）。
COPY pick_rust_version.py /tmp/pick_rust_version.py
RUN mkdir -p /opt/wheels \
 && RUSTV="$(python /tmp/pick_rust_version.py)" \
 && echo "ipv8-rust-tunnels==${RUSTV}" | tee /opt/constraints.txt \
 && RUSTFLAGS="--cfg tokio_unstable" \
    pip wheel --no-deps --no-binary ipv8-rust-tunnels \
      -c /opt/constraints.txt -w /opt/wheels "ipv8-rust-tunnels==${RUSTV}" \
 && ls -l /opt/wheels

# 步驟 3b：先裝自己編譯的 wheel（避免 pip 改抓 PyPI 上有問題的 aarch64 預編譯 wheel），再裝其餘依賴
RUN pip install --no-cache-dir /opt/wheels/ipv8_rust_tunnels-*.whl \
 && pip install --no-cache-dir -c /opt/constraints.txt -r /tribler/requirements.txt \
 && pip list 2>/dev/null | grep -i rust-tunnels

# 步驟 3c：驗證模組與 Tribler 需要的 API，通過後清掉 Rust 與暫存檔
RUN python -c "import ipv8_rust_tunnels as m; from ipv8_rust_tunnels import EndpointNotOpenError; print('ipv8_rust_tunnels OK', [n for n in dir(m) if not n.startswith('_')])" \
 && rm -rf /root/.cargo /root/.rustup /root/.cache /tmp/pick_rust_version.py

# Ingress 用的反向代理（放在編譯層之後，避免讓前面已快取的 Rust 編譯失效）
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx \
 && rm -rf /var/lib/apt/lists/*
COPY nginx.conf.template /opt/nginx.conf.template
COPY ingress_shim.js /opt/ingress_shim.js

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/bin/bash", "/run.sh"]
