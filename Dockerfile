# =============================================================================
# VIRAL EMPIRE - ClawCloud Run Edition
# Optimized for ClawCloud Run Free Tier (4 vCPU, 8GB RAM, 10GB Disk)
# Base: n8n Latest + FFmpeg + yt-dlp + Arabic Fonts
# =============================================================================

# --- Stage 1: Builder ---
FROM node:20-bookworm-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-setuptools \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install n8n globally (latest stable)
RUN npm install -g n8n@latest --omit=dev 2>&1 | tail -5

# --- Stage 2: Final Image ---
FROM node:20-bookworm-slim

LABEL maintainer="Viral Empire"
LABEL description="n8n + FFmpeg + yt-dlp + Arabic Support for ClawCloud Run"

ARG DEBIAN_FRONTEND=noninteractive

# =============================================================================
# Install ALL system packages in ONE layer (reduces image size)
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # --- Core Tools ---
    ca-certificates \
    curl \
    wget \
    gnupg \
    bash \
    tini \
    procps \
    # --- FFmpeg (video processing) ---
    ffmpeg \
    # --- Python (for yt-dlp) ---
    python3 \
    python3-pip \
    python3-setuptools \
    # --- Helper Tools ---
    jq \
    file \
    mediainfo \
    bc \
    git \
    zip \
    unzip \
    # --- Fonts (Arabic subtitles support) ---
    fontconfig \
    fonts-dejavu-core \
    fonts-liberation \
    fonts-noto-core \
    fonts-noto-color-emoji \
    # --- Timezone ---
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && fc-cache -f -v

# =============================================================================
# Install Arabic fonts (Noto Arabic)
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-noto-extra \
    2>/dev/null || true \
    && rm -rf /var/lib/apt/lists/* \
    && fc-cache -f -v

# =============================================================================
# Install yt-dlp (latest)
# =============================================================================
RUN pip3 install --break-system-packages --no-cache-dir yt-dlp \
    && yt-dlp --version

# =============================================================================
# Copy n8n from builder stage
# =============================================================================
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin/n8n /usr/local/bin/n8n

# Verify n8n installation
RUN n8n --version

# =============================================================================
# Timezone Configuration
# =============================================================================
ENV TZ=Asia/Riyadh
ENV GENERIC_TIMEZONE=Asia/Riyadh
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# =============================================================================
# n8n Core Settings - ClawCloud Run Optimized
# =============================================================================
# IMPORTANT: Port 5678 is n8n default - ClawCloud maps it automatically
ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https
ENV NODE_ENV=production

# =============================================================================
# n8n Directory Structure (Persistent Storage on ClawCloud)
# =============================================================================
ENV N8N_USER_FOLDER=/data/.n8n
ENV N8N_CUSTOM_EXTENSIONS=/data/.n8n/custom
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false

# =============================================================================
# WEBHOOK URLs - Set via ClawCloud Environment Variables!
# These are DEFAULTS - override them in ClawCloud Run settings
# =============================================================================
ENV WEBHOOK_URL=https://your-app.cloud.sealos.io
ENV N8N_EDITOR_BASE_URL=https://your-app.cloud.sealos.io

# =============================================================================
# Code Node Permissions (Required for yt-dlp, FFmpeg, fs operations)
# =============================================================================
ENV NODE_FUNCTION_ALLOW_BUILTIN=*
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*
ENV N8N_BLOCK_ENV_ACCESS_IN_NODE=false
ENV EXECUTIONS_PROCESS=main

# =============================================================================
# Task Runner Settings (for long FFmpeg operations)
# =============================================================================
ENV N8N_RUNNERS_ENABLED=true
ENV N8N_RUNNERS_TASK_TIMEOUT=3600
ENV N8N_RUNNERS_MAX_PAYLOAD=1073741824
ENV EXECUTIONS_TIMEOUT=7200
ENV EXECUTIONS_TIMEOUT_MAX=14400

# =============================================================================
# Database Settings (SQLite - stored in persistent /data)
# =============================================================================
ENV DB_TYPE=sqlite
ENV DB_SQLITE_DATABASE=/data/database.sqlite

# =============================================================================
# Execution Data Management (save memory)
# =============================================================================
ENV EXECUTIONS_DATA_PRUNE=true
ENV EXECUTIONS_DATA_MAX_AGE=48
ENV EXECUTIONS_DATA_SAVE_ON_ERROR=all
ENV EXECUTIONS_DATA_SAVE_ON_SUCCESS=none
ENV EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true

# =============================================================================
# Performance Settings (Optimized for 8GB RAM)
# =============================================================================
ENV NODE_OPTIONS="--max-old-space-size=2048 --dns-result-order=ipv4first"
ENV N8N_DIAGNOSTICS_ENABLED=false
ENV N8N_VERSION_NOTIFICATIONS_ENABLED=false
ENV N8N_TEMPLATES_ENABLED=true
ENV N8N_HIRING_BANNER_ENABLED=false
ENV N8N_PERSONALIZATION_ENABLED=false

# =============================================================================
# Create required directories
# =============================================================================
RUN mkdir -p \
    /data/.n8n/config \
    /data/.n8n/database \
    /data/.n8n/workflows \
    /data/.n8n/logs \
    /data/.n8n/custom \
    /data/cookies \
    /tmp/videos \
    /tmp/whisper_audio \
    /tmp/n8n-videos \
    /tmp/n8n-clips \
    && chmod -R 755 /data \
    && chmod 1777 /tmp/videos /tmp/whisper_audio /tmp/n8n-videos /tmp/n8n-clips

# =============================================================================
# Create cookies.txt placeholder
# =============================================================================
RUN touch /data/cookies/cookies.txt && chmod 644 /data/cookies/cookies.txt \
    && ln -sf /data/cookies/cookies.txt /data/cookies.txt

# =============================================================================
# Startup Script
# =============================================================================
COPY start.sh /start.sh
RUN chmod +x /start.sh

# =============================================================================
# Final Configuration
# =============================================================================
WORKDIR /data
EXPOSE 5678

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -sf http://localhost:5678/healthz || exit 1

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]
