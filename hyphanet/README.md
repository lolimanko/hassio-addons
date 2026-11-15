# Hyphanet for Home Assistant Community Add-ons

### Accessing Hyphanet
1. Wait 2-3 minutes for initial setup
2. Open in your browser:
   ```
   http://homeassistant.local:8888/
   ```
   or use Web UI

## Data Persistence
All sensitive data is stored in /addon_configs/fdd0cf77_hyphanet
You can disable Hypha in HAOS backups to prevent the backup files from becoming too large.
## Security Notes
- 🔐 FProxy bound to container network only by default
- 🛡️ All sensitive files stored in isolated volume
- 📜 Automatic log rotation
- ⚠️ Never expose port 8888 publicly without authentication
