FROM ghcr.io/astral-sh/uv:0.11.6-python3.13-trixie@sha256:b3c543b6c4f23a5f2df22866bd7857e5d304b67a564f4feab6ac22044dde719b AS uv_source
FROM debian:13.4

# 環境變數
ENV PYTHONUNBUFFERED=1
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/hermes/.playwright
ENV HERMES_HOME=/opt/data
ENV PATH="/opt/hermes/.venv/bin:$PATH"
ENV HERMES_UID=0   # 強制 root 運行，避免用戶問題

# 安裝系統依賴
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential nodejs npm python3 ripgrep ffmpeg gcc python3-dev libffi-dev procps git \
    && rm -rf /var/lib/apt/lists/*

# 複製 uv
COPY --from=uv_source /usr/local/bin/uv /usr/local/bin/uv
COPY --from=uv_source /usr/local/bin/uvx /usr/local/bin/uvx

WORKDIR /opt/hermes

# 複製整個專案
COPY . .

# 安裝 Node 依賴和 Playwright
RUN npm install --prefer-offline --no-audit && \
    npx playwright install --with-deps chromium --only-shell && \
    cd scripts/whatsapp-bridge && \
    npm install --prefer-offline --no-audit && \
    npm cache clean --force

# 使用 uv 建立 venv 並安裝 Python 依賴（解決 PyYAML 等問題）
RUN uv venv && \
    uv pip install --no-cache-dir -e ".[all]"

# 準備 entrypoint（保留官方腳本，但強制 root）
RUN chmod +x docker/entrypoint.sh

VOLUME [ "/opt/data" ]
ENTRYPOINT [ "/opt/hermes/docker/entrypoint.sh" ]
