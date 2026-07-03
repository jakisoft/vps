#!/bin/bash

# ==========================================
# CONFIGURATION (Silahkan Ubah Sesuai Kebutuhan)
# ==========================================
NEW_PORT="22"
NEW_PASSWORD="Jaki2143" # Ganti dengan password yang kuat!
# ==========================================

# Pastikan script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Harap jalankan script ini sebagai root (atau gunakan sudo)."
  exit 1
fi

echo "⏳ 1. Memperbarui Paket Sistem (Update & Upgrade)..."
apt-get update -y && apt-get upgrade -y

echo "⏳ 2. Mengonfigurasi Password Baru..."
echo "root:$NEW_PASSWORD" | chpasswd
# Jika kamu menggunakan user selain root, contoh ubuntu:
# echo "ubuntu:$NEW_PASSWORD" | chpasswd

echo "⏳ 3. Mengonfigurasi SSH (Port & Akses)..."
SSH_CONFIG="/etc/ssh/sshd_config"

# Backup konfigurasi asli
cp $SSH_CONFIG "${SSH_CONFIG}.bak"

# Atur Port SSH kustom
sed -i "s/^#\?Port.*/Port $NEW_PORT/" $SSH_CONFIG

# Pastikan Root Login dan Password Authentication diizinkan
sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin yes/" $SSH_CONFIG
sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/" $SSH_CONFIG

echo "⏳ 4. Mengambil Informasi IP Publik..."
PUBLIC_IP=$(curl -s ifconfig.me)
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(curl -s icanhazip.com)
fi

echo "⏳ 5. Membuka Port Baru di Firewall (UFW)..."
if command -v ufw >/dev/null; then
    ufw allow $NEW_PORT/tcp
    ufw reload
fi

echo "⏳ 6. Merestart Service SSH..."
systemctl restart sshd || systemctl restart ssh

echo "------------------------------------------------"
echo "✅ KONFIGURASI SELESAI!"
echo "------------------------------------------------"
echo "🌐 IP Publik VPS : $PUBLIC_IP"
echo "🔑 Port SSH Baru : $NEW_PORT"
echo "🔐 Password Baru : $NEW_PASSWORD"
echo "------------------------------------------------"
echo "👉 Silahkan coba login di terminal baru menggunakan:"
echo "   ssh root@$PUBLIC_IP -p $NEW_PORT"
echo "------------------------------------------------"
