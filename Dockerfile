# ═══════════════════════════════════════════════════════════════════════════════
# VIRAL EMPIRE V37.1 - CLAWCLOUDRUN EDITION (Generic + Dynamic)
# تم بناؤه خصيصاً لك - يعمل بدون مشاكل على ClawCloudRun
# ═══════════════════════════════════════════════════════════════════════════════

FROM node:24-alpine

LABEL maintainer="YourName"
LABEL version="37.1-claw"
LABEL description="Viral Empire V37.1 - Optimized for ClawCloudRun Free"

USER root

# تثبيت كل الأدوات المطلوبة (خفيفة جداً)
RUN apk add --no-cache \
    bash curl wget ca-certificates ffmpeg yt-dlp python3 jq git file tzdata tini \
    fontconfig font-noto font-noto-arabic \
    && fc-cache -f -v

# تثبيت أحدث نسخة n8n
RUN npm install -g n8n@latest --omit=dev

# إعدادات n8n + Python
ENV HF_HUB_DISABLE_TELEMETRY=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    HF_ENDPOINT=https://huggingface.co \
    HF_HOME=/tmp \
    N8N_PORT=7860 \
    N8N_HOST=0.0.0.0 \
    N8N_PROTOCOL=https \
    NODE_ENV=production \
    DB_TYPE=sqlite \
    DB_SQLITE_DATABASE=/data/database.sqlite \
    NODE_OPTIONS="--max-old-space-size=2048 --dns-result-order=ipv4first" \
    TZ=Asia/Riyadh \
    NODE_FUNCTION_ALLOW_BUILTIN=* \
    NODE_FUNCTION_ALLOW_EXTERNAL=* \
    N8N_BLOCK_ENV_ACCESS_IN_NODE=false

# إنشاء المجلدات + صلاحيات
RUN mkdir -p /data/.n8n /tmp/videos /tmp/whisper_audio /tmp/n8n-videos /tmp/n8n-clips \
    && chmod -R 777 /data /tmp

# سكريبت البداية (Dynamic Webhook)
RUN cat > /start.sh << 'START'
#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════════════════"
echo "   🔥 VIRAL EMPIRE V37.1 - CLAWCLOUDRUN EDITION 🔥"
echo "   Webhook URL: ${WEBHOOK_URL:-http://localhost:7860}"
echo "═══════════════════════════════════════════════════════════════════"

# Memory Watchdog (يقتل الملفات الكبيرة لو الذاكرة ارتفعت)
(while true; do
    MEM_USED=$(awk '/MemAvailable/ {print int((1 - $2/($(awk "/MemTotal/ {print $2}" /proc/meminfo)) * 100))}' /proc/meminfo 2>/dev/null || echo 0)
    if [ "$MEM_USED" -gt 85 ]; then
        find /tmp -name "*.mp4" -mmin +10 -delete 2>/dev/null || true
        find /tmp -name "*.wav" -mmin +15 -delete 2>/dev/null || true
    fi
    sleep 60
done) &

# ملف الكوكيز (مهم لـ yt-dlp)
touch /data/cookies.txt 2>/dev/null || true
chmod 666 /data/cookies.txt 2>/dev/null || true

echo "🚀 بدء n8n..."
exec n8n start
START

RUN chmod +x /start.sh

WORKDIR /data
EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD wget -q --spider http://localhost:7860/healthz || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/start.sh"]
