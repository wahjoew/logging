#!/bin/bash

# URL endpoint PHP yang mengecek SECRET
CHECK_URL="https://alpha.helinium.net/cek-secret.php"

read -p "Masukkan CODE key: " code

# Cek apakah input kosong
if [ -z "$code" ]; then
    echo "CODE key tidak boleh kosong. Keluar."
    exit 1
fi

# Kirim ke server
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"secret\": \"$code\"}" "$CHECK_URL")

# Ambil status dari response (butuh jq atau bisa manual)
STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d':' -f2 | tr -d '"')

# Validasi
if [ "$STATUS" = "ok" ]; then
    echo "CODE cocok. Akses diberikan."
else
    echo "CODE salah. Keluar."
    exit 1
fi

LOG_SCRIPT_PATH="/usr/local/bin/log_login_gsheet.sh"
SSHRRC_FILE="/etc/ssh/sshrc"

echo "[*] Memasang SSH login logger ke $SSHRRC_FILE..."

# Backup dulu
if [ -f "$SSHRRC_FILE" ]; then
    cp "$SSHRRC_FILE" "${SSHRRC_FILE}.bak.$(date +%s)"
fi

cat <<EOF >> "$SSHRRC_FILE"

# === SSH LOGIN LOGGER ===

# SSH session check
if [ -z "\$SSH_CONNECTION" ]; then
  exit 0
fi

SECRET="$code"

USER=\$(whoami)
IP=\$(echo \$SSH_CONNECTION | awk '{print \$1}')
TIME=\$(date -u '+%Y-%m-%d %H:%M:%S')
HOSTNAME=\$(hostname)

# Replace with your actual webhook URL
WEBHOOK_URL="https://script.google.com/macros/s/AKfycbw5cYkZ8VAZ5DOiJYaThrcTm_LckhOPgAr-2C_oFB0gjAX4_do2DYDzg3GxzcJbvFXk/exec"

curl -s -X POST "\$WEBHOOK_URL" \\
  -d time="\$TIME" \\
  -d user="\$USER" \\
  -d host="\$HOSTNAME" \\
  -d ip="\$IP" \\
  -d secret="\$SECRET" &> /dev/null
# =========================
EOF

echo "[✓] SSH login logger berhasil dipasang di $SSHRRC_FILE"
