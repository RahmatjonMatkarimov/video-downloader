# Telegram Instagram Downloader Bot

## Server setup

1. Copy the repository to the server, for example:
   ```bash
   scp -r /local/path/telegram_bot root@159.194.203.69:/opt/telegram_bot
   ```

2. SSH into the server:
   ```bash
   ssh root@159.194.203.69
   ```

3. Enter the bot directory and run deployment:
   ```bash
   cd /opt/telegram_bot
   ./deploy.sh
   ```

4. If you need to change the bot token, edit `.env`:
   ```bash
   nano .env
   ```

5. Check the service status:
   ```bash
   systemctl status telegram_bot
   ```

## Manual start

If you prefer not to use systemd, run:
```bash
source venv/bin/activate
python3 bot.py
```

## Notes

- `deploy.sh` installs Python, pip, and ffmpeg on Debian/Ubuntu systems automatically.
- The service file is installed to `/etc/systemd/system/telegram_bot.service` when run as root.
- The bot stores temporary downloads in the `downloads/` directory.
