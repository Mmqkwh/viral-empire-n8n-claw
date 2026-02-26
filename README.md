# n8n Viral Empire - ClawCloud Run Edition

Custom n8n Docker image optimized for ClawCloud Run free tier deployment.

## Included Tools
- **n8n** (latest stable)
- **FFmpeg** (video processing)
- **yt-dlp** (video downloading)
- **Python 3** (scripting support)
- **Arabic Fonts** (Noto Arabic for subtitles)
- **mediainfo, jq, git** (helper tools)

## Quick Deploy on ClawCloud Run

### Image: `ghcr.io/YOUR_USERNAME/n8n-viral-empire:latest`

### Required Environment Variables:
```
WEBHOOK_URL=https://YOUR-APP-NAME.cloud.sealos.io
N8N_EDITOR_BASE_URL=https://YOUR-APP-NAME.cloud.sealos.io
```

### Port: `5678`

## Build Locally
```bash
docker build -t n8n-viral-empire .
docker run -d -p 5678:5678 -v n8n_data:/data n8n-viral-empire
```
