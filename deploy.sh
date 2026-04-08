#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Warning: not running as root. Service installation will be skipped."
  SKIP_SYSTEMD=1
else
  SKIP_SYSTEMD=0
fi

if command -v apt-get >/dev/null 2>&1; then
  echo "Installing OS packages..."
  apt-get update
  apt-get install -y python3 python3-venv python3-pip ffmpeg
else
  echo "Package manager not supported by this script."
  echo "Install python3, python3-venv, python3-pip, and ffmpeg manually before continuing."
fi

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

mkdir -p downloads

if [[ ! -f .env ]]; then
  cat > .env <<'EOF'
BOT_TOKEN=8617618303:AAHJOrUSPANSM4hjjnWD5mk2j0w8IDjXRzI
EOF
  echo ".env created. Edit BOT_TOKEN if needed."
fi

if [[ "$SKIP_SYSTEMD" -eq 0 ]]; then
  echo "Installing systemd service..."
  SERVICE_PATH="$(pwd)"
  ENV_FILE="${SERVICE_PATH}/.env"

  if [[ ! -f "$ENV_FILE" ]]; then
    echo ".env file missing, creating default .env file..."
    cat > "$ENV_FILE" <<'EOF'
BOT_TOKEN=8617618303:AAHJOrUSPANSM4hjjnWD5mk2j0w8IDjXRzI
EOF
  fi

  cat > /etc/systemd/system/telegram_bot.service <<EOF
[Unit]
Description=Telegram Instagram Downloader Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${SERVICE_PATH}
ExecStart=${SERVICE_PATH}/venv/bin/python ${SERVICE_PATH}/bot.py
Restart=always
RestartSec=10
EnvironmentFile=-${ENV_FILE}
Environment=PATH=${SERVICE_PATH}/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
StandardOutput=journal
StandardError=journal
SyslogIdentifier=telegram_bot

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable telegram_bot
  systemctl restart telegram_bot
  echo "Systemd service installed and started from ${SERVICE_PATH}."
else
  echo "Run this script as root to install and start the service."
fi

echo "Setup complete."
echo "Manual run: source venv/bin/activate && python3 bot.py"
