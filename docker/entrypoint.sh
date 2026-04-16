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

echo "🚀 Starting hermes in background mode..."

# 背景運行 hermes（使用 gateway 或 chat 模式，視你的 config.yaml 而定）
# 如果你主要用 gateway（如 Telegram/Discord/WhatsApp），建議改用 hermes gateway
# 這裡先用最穩定的方式：直接運行主模組 + tail 保持容器 alive
cd "$INSTALL_DIR"
nohup .venv/bin/python -m hermes_cli.main >> "$HERMES_HOME/logs/hermes.log" 2>&1 &

# 保持容器前台運行，持續輸出 log（Zeabur 需要主進程不退出）
echo "📋 Hermes log tail started. Check $HERMES_HOME/logs/hermes.log for details."
tail -f "$HERMES_HOME/logs/hermes.log"
