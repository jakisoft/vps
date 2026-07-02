#!/bin/bash

clear

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${GREEN}    👹 JKSoft - SSHX TERMINAL CLIENT CONNECTOR 👹       ${NC}"
echo -e "${CYAN}==========================================================${NC}"
echo ""

echo -e "${YELLOW}👉 Masukkan URL sshx yang kamu dapatkan:${NC}"
echo -ne "${CYAN}🔗 URL: ${NC}"
read SSHX_URL

if [ -z "$SSHX_URL" ]; then
    echo -e "${RED}❌ URL tidak boleh kosong! Proses dibatalkan.${NC}"
    exit 1
fi

SSHX_ID=$(echo "$SSHX_URL" | grep -o 'https://sshx.io/s/[a-zA-Z0-9]*' | sed 's|https://sshx.io/s/||')

if [ -z "$SSHX_ID" ]; then
    echo -e "${RED}❌ Format URL sshx tidak valid!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}==========================================================${NC}"
echo -e "🚀 Menghubungkan langsung ke terminal via sshx..."
echo -e "💡 Trik: Untuk keluar dari sesi, ketik ${YELLOW}exit${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo ""

sleep 1

curl -sSf https://sshx.io/get | sh -s -- join "$SSHX_ID"

echo ""
echo -e "${YELLOW}👋 Sesi sshx telah diputus. Kembali ke terminal lokal.${NC}"
