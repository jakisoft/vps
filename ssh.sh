#!/bin/bash

GREEN='\0033;32m'
CYAN='\0033;36m'
YELLOW='\0033;1;33m'
NC='\0033[0m'

LOG_FILE="$HOME/tmate_connection.txt"

pkill tmate
if [ -f /tmp/tmate.sock ]; then
    rm -f /tmp/tmate.sock
fi

if [ -x "$(command -v apt-get)" ]; then
    sudo apt-get update -y && sudo apt-get install tmate -y
elif [ -x "$(command -v yum)" ]; then
    sudo yum install epel-release -y && sudo yum install tmate -y
else
    echo -e "${YELLOW}[!] Package manager tidak didukung.${NC}"
    exit 1
fi

if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t rsa -N "" -f "$HOME/.ssh/id_rsa" <<< y >/dev/null 2>&1
fi

tmate -S /tmp/tmate.sock new-session -d
tmate -S /tmp/tmate.sock wait tmate-ready

SSH_CMD=$(tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}')
WEB_CMD=$(tmate -S /tmp/tmate.sock display -p '#{tmate_web}')

echo "=== TMATE CONNECTION LOG ===" > "$LOG_FILE"
echo "Dibuat pada: $(date)" >> "$LOG_FILE"
echo "----------------------------" >> "$LOG_FILE"
echo "SSH Command : $SSH_CMD" >> "$LOG_FILE"
echo "Web URL     : $WEB_CMD" >> "$LOG_FILE"
echo "============================" >> "$LOG_FILE"

echo -e "\n${GREEN}=== TMATE BERHASIL DIJALANKAN (SESI BARU) ===${NC}"
echo -e "${YELLOW}Koneksi via SSH Terminal:${NC}"
echo -e "${GREEN}$SSH_CMD${NC}\n"
echo -e "${YELLOW}Koneksi via Web Browser:${NC}"
echo -e "${GREEN}$WEB_CMD${NC}\n"
echo -e "-----------------------------------------------------"
echo -e "Detail koneksi lama telah mati. Koneksi baru disimpan di: ${CYAN}$LOG_FILE${NC}"
echo -e "-----------------------------------------------------"
echo -e "Untuk mematikan sesi ini secara manual, jalankan: ${YELLOW}pkill tmate${NC}\n"
