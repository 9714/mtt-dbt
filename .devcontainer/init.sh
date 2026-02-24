#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────
# ADC (Application Default Credentials) 認証
# ────────────────────────────────────────────
ADC_FILE="${HOME}/.config/gcloud/application_default_credentials.json"

echo ""
echo "========================================"
echo "  Google ADC 認証"
echo "========================================"
echo "  【手順】"
echo "  1. 以下に表示される URL をブラウザで開く"
echo "  2. Google アカウントで認証する"
echo "  3. アドレスバーの URL 全体をコピーしてここに貼り付けて Enter"
echo "========================================"
echo ""

gcloud auth application-default login --no-launch-browser --quiet \
    --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/drive

export GOOGLE_APPLICATION_CREDENTIALS="${ADC_FILE}"
echo ""
echo "✅ ADC 認証完了: ${GOOGLE_APPLICATION_CREDENTIALS}"
