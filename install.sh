#!/usr/bin/env bash
set -e

# Install Python dependencies for the Telegram bot and print run instructions.
# Usage: ./install.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "== Telegram bot setup =="

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found. Attempting to install Python 3..."

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y python3 python3-venv python3-pip
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y python3 python3-venv python3-pip
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y python3 python3-venv python3-pip
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm python
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y python3 python3-venv python3-pip
  else
    echo "ERROR: No supported package manager found. Install Python 3.9+ manually."
    exit 1
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 installation failed. Install Python 3.9+ manually."
    exit 1
  fi
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(sys.version_info[:3])')
PYTHON_MAJOR=$(python3 -c 'import sys; print(sys.version_info[0])')
PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info[1])')
if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 9 ]; }; then
  echo "ERROR: Python 3.9 or newer is required. Current version: $(python3 --version)"
  exit 1
fi

if [ ! -f requirements.txt ]; then
  echo "ERROR: requirements.txt not found in $SCRIPT_DIR"
  exit 1
fi

if [ ! -d venv ]; then
  echo "Creating Python virtual environment..."
  python3 -m venv venv
fi

echo "Activating virtual environment and installing dependencies..."
source venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "WARNING: ffmpeg is not installed. Audio extraction will fail until ffmpeg is installed."
  if command -v apt-get >/dev/null 2>&1; then
    echo "You can install ffmpeg with: sudo apt-get update && sudo apt-get install -y ffmpeg"
  elif command -v yum >/dev/null 2>&1; then
    echo "You can install ffmpeg with: sudo yum install -y ffmpeg"
  fi
fi

mkdir -p downloads

echo "\nSetup complete. Run the bot with:" 
echo "  source venv/bin/activate && python bot.py"
echo "or" 
echo "  ./venv/bin/python bot.py"
