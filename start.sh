#!/bin/bash
set -e

echo ""
echo "=================================================================="
echo "   VIRAL EMPIRE - ClawCloud Run Edition"
echo "=================================================================="
echo ""
echo "  System Information:"
echo "  +-- n8n:      $(n8n --version 2>/dev/null || echo 'loading...')"
echo "  +-- Node.js:  $(node --version)"
echo "  +-- FFmpeg:   $(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')"
echo "  +-- yt-dlp:   $(yt-dlp --version 2>/dev/null || echo 'N/A')"
echo "  +-- Python:   $(python3 --version 2>&1 | awk '{print $2}')"
echo ""
echo "  Storage:  $(df -h /data 2>/dev/null | tail -1 | awk '{print $4}') available"
echo "  Timezone: ${TZ:-UTC}"
echo "  Port:     ${N8N_PORT:-5678}"
echo "  Webhook:  ${WEBHOOK_URL:-NOT SET}"
echo ""
echo "=================================================================="

# ---- Ensure directories exist ----
mkdir -p /data/.n8n/config /data/.n8n/custom /data/cookies 2>/dev/null || true
mkdir -p /tmp/videos /tmp/whisper_audio /tmp/n8n-videos /tmp/n8n-clips 2>/dev/null || true
chmod 1777 /tmp/videos /tmp/whisper_audio /tmp/n8n-videos /tmp/n8n-clips 2>/dev/null || true

# ---- Create cookies file if not exists ----
touch /data/cookies/cookies.txt 2>/dev/null || true
touch /data/cookies.txt 2>/dev/null || true

# ---- Update yt-dlp in background (non-blocking) ----
echo "  Updating yt-dlp in background..."
(sleep 30 && yt-dlp -U 2>/dev/null || true) &

# ---- Memory watchdog (background) ----
(while true; do
    MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 1)
    MEM_AVAIL=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo 1)
    MEM_USED_PCT=$(( (MEM_TOTAL - MEM_AVAIL) * 100 / MEM_TOTAL ))
    if [ "$MEM_USED_PCT" -gt 85 ]; then
        echo "[WATCHDOG] Memory: ${MEM_USED_PCT}% - Cleaning temp files..."
        find /tmp/n8n-videos -type f -mmin +5 -delete 2>/dev/null || true
        find /tmp/n8n-clips -type f -mmin +5 -delete 2>/dev/null || true
        find /tmp/whisper_audio -type f -mmin +10 -delete 2>/dev/null || true
        find /tmp/videos -type f -mmin +10 -delete 2>/dev/null || true
    fi
    sleep 60
done) &

# ---- Periodic temp cleanup (every 30 min) ----
(while true; do
    sleep 1800
    find /tmp/n8n-videos -type f -mmin +30 -delete 2>/dev/null || true
    find /tmp/n8n-clips -type f -mmin +30 -delete 2>/dev/null || true
    find /tmp/whisper_audio -type f -mmin +60 -delete 2>/dev/null || true
    find /tmp/videos -type f -mmin +60 -delete 2>/dev/null || true
done) &

echo ""
echo "  Starting n8n..."
echo "=================================================================="
echo ""

exec n8n start
