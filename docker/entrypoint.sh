#!/bin/bash
# Docker entrypoint for Zeabur: bootstrap config files, then run hermes in background mode.
# Modified for Zeabur: skip user switch, run as root, keep container alive.

set -e

HERMES_HOME="${HERMES_HOME:-/opt/data}"
INSTALL_DIR="/opt/hermes"

echo "🚀 Running in Zeabur root-compatible mode (skipping hermes user switch)"

# --- Running as root ---
source "${INSTALL_DIR}/.venv/bin/activate"

# 建立必要目錄與初始化檔案
mkdir -p "$HERMES_HOME"/{cron,sessions,logs,hooks,memories,skills,skins,plans,workspace,home}

if [ ! -f "$HERMES_HOME/.env" ]; then
    cp "$INSTALL_DIR/.env.example" "$HERMES_HOME/.env"
    echo "✅ Created .env from example"
fi

if [ ! -f "$HERMES_HOME/config.yaml" ]; then
    cp "$INSTALL_DIR/cli-config.yaml.example" "$HERMES_HOME/config.yaml"
    echo "✅ Created config.yaml from example"
fi

if [ ! -f "$HERMES_HOME/SOUL.md" ]; then
    cp "$INSTALL_DIR/docker/SOUL.md" "$HERMES_HOME/SOUL.md"
    echo "✅ Created SOUL.md"
fi

if [ -d "$INSTALL_DIR/skills" ]; then
    python3 "$INSTALL_DIR/tools/skills_sync.py" || echo "⚠️ Warning: skills_sync.py failed"
fi

echo "🚀 Starting hermes gateway in background mode..."

cd "$INSTALL_DIR"
mkdir -p "$HERMES_HOME/logs"

# 使用絕對路徑啟用 venv
. "$INSTALL_DIR/.venv/bin/activate"

nohup hermes gateway >> "$HERMES_HOME/logs/hermes.log" 2>&1 &

echo "📋 Hermes gateway started. Check logs: $HERMES_HOME/logs/hermes.log"
sleep 3
tail -f "$HERMES_HOME/logs/hermes.log" || tail -f /dev/null
