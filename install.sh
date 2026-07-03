#!/bin/bash

clear

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

type_effect() {
    local text="$1"
    local delay="$2"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

loading_bar() {
    local title="$1"
    echo -ne "${YELLOW}⏳ $title ${NC}[          ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[===       ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[======    ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[========= ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[==========]"
    echo -e " ${GREEN}DONE!${NC}"
}

if [ "$(id -u)" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

show_menu() {
    clear
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}          [👹 JKSOFT PREMIUM VPS DASHBOARD 👹]           ${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}                ┌─────────────────────────┐               ${NC}"
    echo -e "${WHITE}                │   ${RED}█▀▀█ █──█ █▄─▄█ █▀▀█${WHITE}  │  <[SUKUNA V2] ${NC}"
    echo -e "${WHITE}                │   ${RED}█▄▄█ █▄▄█ █ █ █ █▄▄█${WHITE}  │               ${NC}"
    echo -e "${WHITE}                └─────────────────────────┘               ${NC}"
    echo -e "${PURPLE}                     (█)─(█)     (█)─(█)                  ${NC}"
    echo -e "${PURPLE}                    █████████   █████████                 ${NC}"
    echo -e "${RED}                   ███████████████████████                ${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo -e "${CYAN}  ____  _____ _   _ ____     ____    _    __  __ ___ _   _  ____ ${NC}"
    echo -e "${CYAN} |  _ \| ____| | | |  _ \   / ___|  / \  |  \/  |_ _| \ | |/ ___|${NC}"
    echo -e "${CYAN} | | | |  _| | | | | |_) | | |  _  / _ \ | |\/| || ||  \| | |  _ ${NC}"
    echo -e "${CYAN} | |_| | |___| |_| |  __/  | |_| |/ ___ \| |  | || || |\  | |_| |${NC}"
    echo -e "${CYAN} |____/|_____|\___/|_|      \____/_/   \_\_|  |_|___|_| \_|\____|${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo ""
    echo -e "${YELLOW}👉 SELECT AN OPTION TO PROCEED FROM LIST:${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Create & Boot New NAT VPS Instance"
    echo -e "  ${CYAN}[2]${NC} Restart Existing VPS Instance"
    echo -e "  ${CYAN}[3]${NC} Modify TCP Port Forward Rules (Default: 2222)"
    echo -e "  ${CYAN}[4]${NC} Remove/Clean VPS Cache Files"
    echo -e "  ${CYAN}[5]${NC} Exit Dashboard"
    echo ""
    echo -e "${RED}==========================================================${NC}"
    echo -ne "${WHITE}🔹 Enter Choice [1-5]: ${NC}"
    read CHOICE
    
    case $CHOICE in
        1) create_vps ;;
        2) restart_vps ;;
        3) configure_tcp ;;
        4) clean_vps ;;
        5) exit 0 ;;
        *) echo -e "${RED}❌ Invalid Choice! Please select 1-5.${NC}"; sleep 2; show_menu ;;
    esac
}

create_vps() {
    clear
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}⚙️  CONFIGURE YOUR VIRTUAL MACHINE SPECIFICATIONS${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo ""
    
    echo -e "${YELLOW}👉 CHOOSE OPERATING SYSTEM:${NC}"
    echo -e "  ${CYAN}[1]${NC} Ubuntu 22.04 LTS"
    echo -e "  ${CYAN}[2]${NC} Ubuntu 24.04 LTS"
    echo -e "  ${CYAN}[3]${NC} Debian 12 Bookworm"
    echo -ne "${WHITE}🔹 Select OS [1-3]: ${NC}"
    read OS_CHOICE

    case $OS_CHOICE in
        1)
            OS_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
            OS_IMG="ubuntu22.qcow2"
            ;;
        2)
            OS_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
            OS_IMG="ubuntu24.qcow2"
            ;;
        3)
            OS_URL="https://cloudimages.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
            OS_IMG="debian12.qcow2"
            ;;
        *)
            echo -e "${RED}❌ Invalid Option! Defaulting to Ubuntu 22.04.${NC}"
            OS_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
            OS_IMG="ubuntu22.qcow2"
            sleep 1
            ;;
    esac

    echo ""
    echo -ne "${BLUE}🔹 Enter RAM Size in GB (e.g., 4, 8, 16, 32): ${NC}"
    read RAM_GB
    echo -ne "${BLUE}🔹 Enter CPU Cores (e.g., 2, 4, 8): ${NC}"
    read CPU_CORES
    echo -ne "${BLUE}🔹 Enter Disk Space to ADD in GB (e.g., 10, 20): ${NC}"
    read DISK_ADD
    echo -ne "${BLUE}🔹 Create Password for root (Default: 1234): ${NC}"
    read USER_PASS
    USER_PASS=${USER_PASS:-1234}
    
    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=22

    echo ""
    echo -e "${YELLOW}⏳ Injecting Core High-Speed Network Drivers... Please wait.${NC}"
    echo ""
    
    $SUDO_CMD apt-get update -y > /dev/null 2>&1
    $SUDO_CMD apt-get install -y qemu-system-x86 qemu-utils wget cloud-image-utils curl tmate openssh-client > /dev/null 2>&1
    
    $SUDO_CMD mkdir -p /home/nat > /dev/null 2>&1
    
    if [ ! -f "/home/nat/$OS_IMG" ]; then
        echo -e "${YELLOW}📥 Downloading Cloud Image to /home/nat/...${NC}"
        $SUDO_CMD wget -q --show-progress "$OS_URL" -O /home/nat/$OS_IMG
        $SUDO_CMD chmod 666 /home/nat/$OS_IMG
    else
        echo -e "${GREEN}✅ Existing Image Cache Detected at /home/nat/.${NC}"
    fi
    
    loading_bar "Generating Cloud-Init Matrix"
    cat <<EOF > user-data
#cloud-config
ssh_pwauth: True
chpasswd:
  list: |
    root:${USER_PASS}
  expire: False
packages:
  - curl
  - wget
  - tmux
runcmd:
  - sed -i 's|#\?\s*\(PermitRootLogin\).*|\1 yes|g' /etc/ssh/sshd_config
  - sed -i 's|#\?\s*\(PasswordAuthentication\).*|\1 yes|g' /etc/ssh/sshd_config
  - echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
  - echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
  - systemctl restart sshd
EOF

    cloud-localds seed.img user-data > /dev/null 2>&1
    loading_bar "Expanding Server Hard Disk Allocation"
    $SUDO_CMD qemu-img resize /home/nat/$OS_IMG +${DISK_ADD}G > /dev/null 2>&1
    
    RANDOM_ID=$(tr -dc 'a-z0-9' < /dev/dev/urandom | head -c 10)
    
    save_env
    boot_qemu
}

configure_tcp() {
    clear
    echo -e "${YELLOW}==========================================================${NC}"
    echo -e "${WHITE}🔄⚙️  MANAGE CUSTOM TCP PORT FORWARDING RULES ${NC}"
    echo -e "${YELLOW}==========================================================${NC}"
    echo ""
    if [ -f ".vps_env" ]; then
        source .vps_env
    fi
    echo -e "Current Target Host Port  : ${CYAN}${TCP_HOST_PORT:-2222}${NC}"
    echo -e "Current Guest VM Port     : ${CYAN}${TCP_GUEST_PORT:-22}${NC}"
    echo ""
    echo -ne "${BLUE}🔹 Enter NEW External Host Port (Default base: 2222): ${NC}"
    read NEW_HOST_PORT
    TCP_HOST_PORT=${NEW_HOST_PORT:-2222}
    
    echo -ne "${BLUE}🔹 Enter Internal Guest Port (Default SSH: 22): ${NC}"
    read NEW_GUEST_PORT
    TCP_GUEST_PORT=${NEW_GUEST_PORT:-22}
    
    save_env
    echo ""
    echo -e "${GREEN}✅ TCP Rule Updated Successfully!${NC}"
    sleep 2
    show_menu
}

save_env() {
    echo "RAM_GB=${RAM_GB:-32}" > .vps_env
    echo "CPU_CORES=${CPU_CORES:-4}" >> .vps_env
    echo "USER_PASS=${USER_PASS:-1234}" >> .vps_env
    echo "TCP_HOST_PORT=${TCP_HOST_PORT:-2222}" >> .vps_env
    echo "TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}" >> .vps_env
    echo "OS_IMG=${OS_IMG:-ubuntu22.qcow2}" >> .vps_env
    echo "RANDOM_ID=${RANDOM_ID:-vpsnat10dg}" >> .vps_env
}

boot_qemu() {
    if [ -f ".vps_env" ]; then
        source .vps_env
    fi

    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}
    RAM_VALUE="${RAM_GB:-32}G"

    clear
    echo -e "${GREEN}==========================================================${NC}"
    type_effect "👹 DATA SYSTEM SYNCHRONIZED! PIPING TERMINAL CHANNELS..." 0.02
    echo -e "${GREEN}==========================================================${NC}"
    echo ""
    
    pkill -f tmate > /dev/null 2>&1
    rm -f /tmp/tmate.sock > /dev/null 2>&1
    
    tmate -S /tmp/tmate.sock new-session -d > /dev/null 2>&1
    tmate -S /tmp/tmate.sock wait tmate-ready > /dev/null 2>&1
    
    sleep 3
    TMATE_SSH=$(tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}')

    clear
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "🎉              JKSOFT - VM NETWORK ACTIVE          "
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${WHITE}👤 Username   : ${CYAN}root${NC}"
    echo -e "${WHITE}🔑 Password   : ${CYAN}${USER_PASS:-1234}${NC}"
    echo -e "${WHITE}⚙️  Resources  : ${CYAN}${RAM_VALUE} RAM | ${CPU_CORES:-4} Cores${NC}"
    echo -e "${WHITE}🆔 NAT ID     : ${CYAN}${RANDOM_ID}${NC}"
    echo -e "${WHITE}🚀 Port Rule  : ${YELLOW}Host Port ${TCP_HOST_PORT} -> VM Port ${TCP_GUEST_PORT}${NC}"
    echo -e "${RED}----------------------------------------------------------${NC}"
    
    if [ ! -z "$TMATE_SSH" ]; then
        echo -e "${GREEN}✅ SSH BERHASIL REGENERASI !${NC}"
        echo ""
        echo -e "${WHITE}🔑 New SSH :${NC}"
        echo -e "${CYAN}$TMATE_SSH${NC}"
        echo ""
        echo -e "${YELLOW}⚠️ Old session sudah expired !${NC}"
    else
        echo -e "${RED}⚠️ Gagal mendapatkan tunnel public tmate. Menggunakan fallback lokal.${NC}"
        echo -e "${WHITE}👉 Connection Command : ssh root@localhost -p ${TCP_HOST_PORT}${NC}"
    fi
    echo -e "${GREEN}==========================================================${NC}"
    echo ""
    
    qemu-system-x86_64 \
        -hda /home/nat/$OS_IMG \
        -m $RAM_VALUE \
        -smp ${CPU_CORES:-4} \
        -drive file=seed.img,format=raw \
        -nographic \
        -netdev user,id=net0,net=10.0.2.0/24,dns=1.1.1.1,hostfwd=tcp::${TCP_HOST_PORT}-:${TCP_GUEST_PORT} \
        -device e1000,netdev=net0
}

restart_vps() {
    if [ -f ".vps_env" ]; then
        source .vps_env
    fi
    if [ -f "/home/nat/$OS_IMG" ] && [ -f "seed.img" ]; then
        echo -e "${GREEN}🔄 Restarting existing server architecture...${NC}"
        sleep 1
        boot_qemu
    else
        echo -e "${RED}❌ No active configuration blocks found! Build module using Option 1.${NC}"
        sleep 3
        show_menu
    fi
}

clean_vps() {
    echo -e "${RED}⚠️ Purging system storage components and configurations...${NC}"
    if [ -f ".vps_env" ]; then
        source .vps_env
    fi
    $SUDO_CMD rm -rf user-data seed.img /home/nat/${OS_IMG:-*.qcow2} .vps_env
    pkill -f tmate > /dev/null 2>&1
    rm -f /tmp/tmate.sock > /dev/null 2>&1
    sleep 1
    echo -e "${GREEN}✅ Workspace successfully wiped fresh!${NC}"
    sleep 2
    show_menu
}

show_menu
