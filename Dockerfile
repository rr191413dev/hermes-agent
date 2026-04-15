FROM ghcr.io/astral-sh/uv:0.11.6-python3.13-trixie@sha256:b3c543b6c4f23a5f2df22866bd7857e5d304b67a564f4feab6ac22044dde719b AS uv_source
FROM debian:13.4

ENV PYTHONUNBUFFERED=1
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/hermes/.playwright
ENV HERMES_HOME=/opt/data
ENV PATH="/opt/hermes/.venv/bin:$PATH"

# 安裝系統依賴（包含 uv 需要的 build tools）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential nodejs npm python3 ripgrep ffmpeg gcc python3-dev libffi-dev procps git \
    && rm -rf /var/lib/apt/lists/*

# 複製 uv
COPY --from=uv_source /usr/local/bin/uv /usr/local/bin/uv
COPY --from=uv_source /usr/local/bin/uvx /usr/local/bin/uvx

WORKDIR /opt/hermes

# 先複製依賴相關檔案，讓 Docker cache 更有效
COPY pyproject.toml ./
COPY requirements.txt ./
COPY README.md ./
COPY setup.py ./ 2>/dev/null || true

# 複製整個專案
COPY . .

# 安裝 Node 依賴和 Playwright
RUN npm install --prefer-offline --no-audit && \
    npx playwright install --with-deps chromium --only-shell && \
    cd scripts/whatsapp-bridge && \
    npm install --prefer-offline --no-audit && \
    npm cache clean --force

# 建立 venv 並安裝 Python 依賴（使用 uv，關鍵步驟）
RUN uv venv && \
    uv pip install --no-cache-dir -e ".[all]"

# 權限處理（Zeabur 通常以 root 運行）
RUN chmod +x docker/entrypoint.sh

VOLUME [ "/opt/data" ]
ENTRYPOINT [ "/opt/hermes/docker/entrypoint.sh" ]
