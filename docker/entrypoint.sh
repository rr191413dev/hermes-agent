#!/bin/bash
# Docker entrypoint for Zeabur: bootstrap config files, then run hermes (root mode)
set -e

HERMES_HOME="${HERMES_HOME:-/opt/data}"
INSTALL_DIR="/opt/hermes"

# --- Zeabur 專用：強制 root 運行，跳過 hermes 用戶切換 ---
# 註解掉原本的 gosu / usermod 邏輯，避免 "user 'hermes' does not exist" 錯誤

# if [ "$(id -u)" = "0" ]; then
#     ...（原本的 privilege dropping 區塊全部註解或刪除）
# fi

# --- 直接以 root 繼續執行初始化 ---
echo "Running as root (Zeabur compatible mode)"

source "${INSTALL_DIR}/.venv/bin/activate"

# 建立必要目錄
mkdir -p "$HERMES_HOME"/{cron,sessions,logs,hooks,memories,skills,skins,plans,workspace,home}

# .env
if [ ! -f "$HERMES_HOME/.env" ]; then
    cp "$INSTALL_DIR/.env.example" "$HERMES_HOME/.env"
    echo "✅ Created .env from example"
fi

# config.yaml
if [ ! -f "$HERMES_HOME/config.yaml" ]; then
    cp "$INSTALL_DIR/cli-config.yaml.example" "$HERMES_HOME/config.yaml"
    echo "✅ Created config.yaml from example"
fi

# SOUL.md
if [ ! -f "$HERMES_HOME/SOUL.md" ]; then
    cp "$INSTALL_DIR/docker/SOUL.md" "$HERMES_HOME/SOUL.md"
    echo "✅ Created SOUL.md"
fi

# Sync bundled skills
if [ -d "$INSTALL_DIR/skills" ]; then
    python3 "$INSTALL_DIR/tools/skills_sync.py" || echo "Warning: skills_sync.py failed"
fi

echo "🚀 Starting hermes..."
exec hermes "$@"
