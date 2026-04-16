#!/bin/bash
# Docker entrypoint for Zeabur: bootstrap config files into the mounted volume, then run hermes.
# Modified for Zeabur compatibility: skip user switching (hermes user does not exist in this env)

set -e

HERMES_HOME="${HERMES_HOME:-/opt/data}"
INSTALL_DIR="/opt/hermes"

# --- Zeabur 專用：強制 root 運行，跳過原本的 gosu / usermod 邏輯 ---
echo "🚀 Running in Zeabur root-compatible mode (skipping hermes user switch)"

# --- Running as root from here ---
source "${INSTALL_DIR}/.venv/bin/activate"

# Create essential directory structure
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

# Sync bundled skills (manifest-based so user edits are preserved)
if [ -d "$INSTALL_DIR/skills" ]; then
    python3 "$INSTALL_DIR/tools/skills_sync.py" || echo "⚠️ Warning: skills_sync.py failed"
fi

echo "🚀 Starting hermes..."
exec hermes "$@"
