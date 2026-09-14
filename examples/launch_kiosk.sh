#!/usr/bin/env bash
# Example invocation script for launching VKS Kiosk in Video Conference Mode
set -euo pipefail

export KIOSK_TARGET="vks"
export KIOSK_URL="https://vks.bayern.de"

echo "Starting VKS Kiosk Browser..."
BROWSER_BIN=$(command -v vivaldi || command -v vivaldi-stable || command -v chromium-browser || command -v chromium)

exec "$BROWSER_BIN" \
    --app="$KIOSK_URL" \
    --kiosk \
    --incognito \
    --use-fake-ui-for-media-stream \
    --autoplay-policy=no-user-gesture-required \
    --check-for-update-interval=31536000 \
    --enable-gpu \
    --ignore-gpu-blocklist \
    --no-first-run
