#!/bin/bash
# Docker entrypoint for Zeabur: bootstrap config files, then run hermes in non-interactive mode.
# Modified for Zeabur: skip user switch, run as root, avoid TUI.

set -e

HERMES_HOME="${HERMES_HOME:-/opt/data}"
INSTALL_DIR="/opt/hermes"

echo "🚀 Running in Zeabur root-compatible mode (skipping hermes user switch)"

# --- Running as root ---
source "${INSTALL_DIR}/.venv/bin/activate"

# 建立必要目錄與初始化檔案（保留官方功能）
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

echo "🚀 Starting hermes in non-interactive mode..."
# 關鍵：用 --non-interactive 或直接以 daemon 方式運行（避免 TUI 退出）
# 如果 hermes 支持 background 模式，或用 nohup / tail -f 保持容器 alive
exec nohup hermes --non-interactive "$@" > "$HERMES_HOME/logs/hermes.log" 2>&1 &
tail -f "$HERMES_HOME/logs/hermes.log"   # 保持容器前台運行，輸出 logs
