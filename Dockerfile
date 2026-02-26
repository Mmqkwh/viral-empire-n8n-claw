# ═══════════════════════════════════════════════════════════════════════════════
# VIRAL EMPIRE V37.1 - CLAWCLOUDRUN EDITION (Fixed Parse Error)
# ═══════════════════════════════════════════════════════════════════════════════

FROM node:24-alpine

LABEL maintainer="YourName"
LABEL version="37.1-claw"
LABEL description="Viral Empire V37.1 - ClawCloudRun Ready"

USER root

# تثبيت كل الأدوات المطلوبة
RUN apk add --no-cache \
    bash curl wget ca-certificates ffmpeg yt-dlp python3 jq git tzdata tini \
    fontconfig font-noto font-noto-arabic \
    && fc-cache -f -v

# تثبيت أحدث n8n
RUN npm install -g n8n@latest --omit=dev

# إعدادات البيئة
ENV HF_HUB_DISABLE_TELEMETRY=1 \
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

# إنشاء المجلدات
RUN mkdir -p /data/.n8n /tmp/videos /tmp/whisper_audio /tmp/n8n-videos /tmp/n8n-clips \
    && chmod -R 777 /data /tmp

# نسخ سكريبت البداية (الطريقة الآمنة)
COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /data
EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD wget -q --spider http://localhost:7860/healthz || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/start.sh"]
