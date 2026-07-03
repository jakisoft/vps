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

mkdir -p /home/nat/master
mkdir -p /home/nat/instances

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
    echo ""
    echo -e "${YELLOW}👉 SELECT AN OPTION TO PROCEED FROM LIST:${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Create & Boot New NAT VPS Instance"
    echo -e "  ${CYAN}[2]${NC} List VM NAT Active Instance"
    echo -e "  ${CYAN}[3]${NC} Configuration & VM Management Panel (Index Select)"
    echo -e "  ${CYAN}[4]${NC} Exit Dashboard"
    echo ""
    echo -e "${RED}==========================================================${NC}"
    echo -ne "${WHITE}🔹 Enter Choice [1-4]: ${NC}"
    read CHOICE
    
    case $CHOICE in
        1) create_vps ;;
        2) list_vm ;;
        3) config_panel ;;
        4) exit 0 ;;
        *) echo -e "${RED}❌ Invalid Choice! Please select 1-4.${NC}"; sleep 2; show_menu ;;
    esac
}

create_vps() {
    clear
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}⚙️  CREATE NEW MULTI-TENANT VIRTUAL MACHINE NAT${NC}"
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
            OS="https://cloudimages.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
            OS_IMG="debian12.qcow2"
            ;;
        *)
            OS_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
            OS_IMG="ubuntu22.qcow2"
            ;;
    esac

    echo ""
    echo -ne "${BLUE}🔹 Enter RAM Size in GB (e.g., 4, 8, 16, 32): ${NC}"
    read RAM_GB
    echo -ne "${BLUE}🔹 Enter CPU Cores (e.g., 2, 4, 8): ${NC}"
    read CPU_CORES
    echo -ne "${BLUE}🔹 Enter Disk Space to ADD in GB (e.g., 10, 20): ${NC}"
    read DISK_ADD
    
    while true; do
        echo -ne "${BLUE}🔹 Enter Custom External Host Port (e.g., 2222, 5000): ${NC}"
        read TCP_HOST_PORT
        TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
        
        if lsof -Pi :$TCP_HOST_PORT -sTCP:LISTEN -t >/dev/null 2>&1 || [ -f "/home/nat/instances/*/.vps_env" ] && grep -q "TCP_HOST_PORT=$TCP_HOST_PORT" /home/nat/instances/*/.vps_env 2>/dev/null; then
            echo -e "${RED}❌ Port $TCP_HOST_PORT sudah digunakan oleh system atau VM lain! Silakan pilih port lain.${NC}"
        else
            break
        fi
    done

    RANDOM_ID=$(tr -dc 'a-z0-9' < /dev/urandom | head -c 10)
    INSTANCE_DIR="/home/nat/instances/$RANDOM_ID"
    $SUDO_CMD mkdir -p "$INSTANCE_DIR"

    echo ""
    echo -e "${YELLOW}⏳ Injecting Core High-Speed Network Drivers & Dependencies...${NC}"
    echo ""
    
    $SUDO_CMD apt-get update -y > /dev/null 2>&1
    $SUDO_CMD apt-get install -y qemu-system-x86 qemu-utils wget cloud-image-utils curl tmate openssh-client lsof > /dev/null 2>&1
    
    if [ ! -f "/home/nat/master/$OS_IMG" ]; then
        echo -e "${YELLOW}📥 Downloading Cloud Image Master to /home/nat/master/...${NC}"
        $SUDO_CMD wget -q --show-progress "$OS_URL" -O /home/nat/master/$OS_IMG
        $SUDO_CMD chmod 666 /home/nat/master/$OS_IMG
    fi

    $SUDO_CMD cp /home/nat/master/$OS_IMG "$INSTANCE_DIR/$OS_IMG"
    $SUDO_CMD chmod 666 "$INSTANCE_DIR/$OS_IMG"
    
    loading_bar "Generating Cloud-Init Sandbox Matrix"
    cat <<EOF > "$INSTANCE_DIR/user-data"
#cloud-config
ssh_pwauth: False
preserve_hostname: false
hostname: ${RANDOM_ID}
packages:
  - curl
  - wget
  - tmux
runcmd:
  - sed -i 's|#\?\s*\(PermitRootLogin\).*|\1 yes|g' /etc/ssh/sshd_config
  - sed -i 's|#\?\s*\(PasswordAuthentication\).*|\1 yes|g' /etc/ssh/sshd_config
  - echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
  - echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
  - echo "127.0.1.1 ${RANDOM_ID}" >> /etc/hosts
  - hostnamectl set-hostname ${RANDOM_ID}
  - systemctl restart sshd
EOF

    cd "$INSTANCE_DIR"
    cloud-localds seed.img user-data > /dev/null 2>&1
    loading_bar "Expanding Isolated Hard Disk Allocation"
    $SUDO_CMD qemu-img resize "$INSTANCE_DIR/$OS_IMG" +${DISK_ADD}G > /dev/null 2>&1
    
    TCP_GUEST_PORT=22
    save_env "$INSTANCE_DIR"
    boot_qemu "$INSTANCE_DIR"
}

list_vm() {
    clear
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "📋              JKSOFT - ACTIVE NAT VM LIST               "
    echo -e "${GREEN}==========================================================${NC}"
    echo ""
    
    local count=0
    for dir in /home/nat/instances/*; do
        if [ -d "$dir" ] && [ -f "$dir/.vps_env" ]; then
            source "$dir/.vps_env"
            count=$((count+1))
            echo -e "${CYAN}[$count]${NC} NAT ID: ${WHITE}${RANDOM_ID}${NC} | OS: ${WHITE}${OS_IMG}${NC} | Port: ${YELLOW}${TCP_HOST_PORT}${NC} | Specs: ${WHITE}${RAM_GB}G RAM, ${CPU_CORES} Cores${NC}"
        fi
    done

    if [ $count -eq 0 ]; then
        echo -e "${RED}❌ No active VM instances detected.${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}==========================================================${NC}"
    echo -ne "${WHITE}Press [Enter] to return to menu...${NC}"
    read
    show_menu
}

config_panel() {
    clear
    echo -e "${YELLOW}==========================================================${NC}"
    echo -e "${WHITE}⚙️🛠️  JKSOFT MULTI-INSTANCE CONFIGURATION PANEL${NC}"
    echo -e "${YELLOW}==========================================================${NC}"
    echo ""
    
    local count=0
    local dirs=()
    for dir in /home/nat/instances/*; do
        if [ -d "$dir" ] && [ -f "$dir/.vps_env" ]; then
            count=$((count+1))
            dirs+=("$dir")
            source "$dir/.vps_env"
            echo -e "  ${CYAN}[$count]${NC} ID: ${WHITE}${RANDOM_ID}${NC} (Port: ${YELLOW}${TCP_HOST_PORT}${NC} | ${RAM_GB}G RAM)"
        fi
    done

    if [ $count -eq 0 ]; then
        echo -e "${RED}❌ No existing VM instances available to manage.${NC}"
        sleep 2
        show_menu
        return
    fi

    echo ""
    echo -ne "${WHITE}🔹 Select VM Index [1-$count] to manage (or 0 to cancel): ${NC}"
    read INDEX_CHOICE

    if [ "$INDEX_CHOICE" -eq 0 ] || [ "$INDEX_CHOICE" -gt "$count" ] 2>/dev/null; then
        show_menu
        return
    fi

    TARGET_DIR="${dirs[$((INDEX_CHOICE-1))]}"
    
    clear
    source "$TARGET_DIR/.vps_env"
    echo -e "${PURPLE}📍 Managing VM ID: $RANDOM_ID${NC}"
    echo -e "----------------------------------------------------------"
    echo -e "  ${CYAN}[1]${NC} Update Resources (RAM, CPU, Custom Port)"
    echo -e "  ${CYAN}[2]${NC} Regenerate tmate Public SSH Session Only"
    echo -e "  ${CYAN}[3]${NC} Delete & Wipe This Instance Completely"
    echo -e "  ${CYAN}[4]${NC} Cancel"
    echo -e "----------------------------------------------------------"
    echo -ne "${WHITE}🔹 Enter Choice [1-4]: ${NC}"
    read TARGET_ACTION

    case $TARGET_ACTION in
        1) update_vm_spec "$TARGET_DIR" ;;
        2) regenerate_ssh "$TARGET_DIR" ;;
        3) delete_vm "$TARGET_DIR" ;;
        *) config_panel ;;
    esac
}

update_vm_spec() {
    local dir="$1"
    clear
    source "$dir/.vps_env"
    echo -e "${YELLOW}⚙️  UPDATE SPECIFICATION FOR VM: $RANDOM_ID${NC}"
    echo ""
    
    echo -ne "${BLUE}🔹 Enter NEW RAM Size in GB (Leave empty to keep ${RAM_GB}G): ${NC}"
    read NEW_RAM
    RAM_GB=${NEW_RAM:-$RAM_GB}
    
    echo -ne "${BLUE}🔹 Enter NEW CPU Cores (Leave empty to keep ${CPU_CORES}): ${NC}"
    read NEW_CPU
    CPU_CORES=${NEW_CPU:-$CPU_CORES}
    
    while true; do
        echo -ne "${BLUE}🔹 Enter NEW Custom External Host Port (Leave empty to keep ${TCP_HOST_PORT}): ${NC}"
        read NEW_PORT
        NEW_PORT=${NEW_PORT:-$TCP_HOST_PORT}
        
        if [ "$NEW_PORT" != "$TCP_HOST_PORT" ] && ( lsof -Pi :$NEW_PORT -sTCP:LISTEN -t >/dev/null 2>&1 || [ -f "/home/nat/instances/*/.vps_env" ] && grep -q "TCP_HOST_PORT=$NEW_PORT" /home/nat/instances/*/.vps_env 2>/dev/null ); then
            echo -e "${RED}❌ Port $NEW_PORT bentrok dengan sistem atau VM aktif lainnya!${NC}"
        else
            TCP_HOST_PORT=$NEW_PORT
            break
        fi
    done
    
    save_env "$dir"
    echo -e "${GREEN}✅ Data updated! Rebooting container...${NC}"
    sleep 1
    boot_qemu "$dir"
}

regenerate_ssh() {
    local dir="$1"
    echo -e "${YELLOW}🔄 Regenerating isolated tmate session...${NC}"
    boot_qemu "$dir"
}

delete_vm() {
    local dir="$1"
    source "$dir/.vps_env"
    echo -e "${RED}⚠️ Purging instance block $RANDOM_ID data permanently...${NC}"
    
    pkill -f "/tmp/$RANDOM_ID" > /dev/null 2>&1
    pkill -f "qemu-system-x86_64.*$RANDOM_ID" > /dev/null 2>&1
    rm -f "/tmp/$RANDOM_ID" > /dev/null 2>&1
    
    $SUDO_CMD rm -rf "$dir"
    sleep 1
    echo -e "${GREEN}✅ Instance successfully wiped fresh!${NC}"
    sleep 2
    show_menu
}

save_env() {
    local dir="$1"
    echo "RAM_GB=${RAM_GB:-32}" > "$dir/.vps_env"
    echo "CPU_CORES=${CPU_CORES:-4}" >> "$dir/.vps_env"
    echo "TCP_HOST_PORT=${TCP_HOST_PORT:-2222}" >> "$dir/.vps_env"
    echo "TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}" >> "$dir/.vps_env"
    echo "OS_IMG=${OS_IMG}" >> "$dir/.vps_env"
    echo "RANDOM_ID=${RANDOM_ID}" >> "$dir/.vps_env"
}

boot_qemu() {
    local dir="$1"
    source "$dir/.vps_env"

    RAM_VALUE="${RAM_GB:-32}G"

    clear
    echo -e "${GREEN}==========================================================${NC}"
    type_effect "👹 DATA SYSTEM SYNCHRONIZED! PIPING BACKGROUND CHANNELS..." 0.02
    echo -e "${GREEN}==========================================================${NC}"
    echo ""
    
    pkill -f "/tmp/$RANDOM_ID" > /dev/null 2>&1
    pkill -f "qemu-system-x86_64.*$RANDOM_ID" > /dev/null 2>&1
    rm -f "/tmp/$RANDOM_ID" > /dev/null 2>&1
    
    tmate -S "/tmp/$RANDOM_ID" new-session -d > /dev/null 2>&1
    
    local timeout=0
    TMATE_SSH=""
    while [ $timeout -lt 10 ]; do
        sleep 1
        TMATE_SSH=$(tmate -S "/tmp/$RANDOM_ID" display -p '#{tmate_ssh}' 2>/dev/null)
        if [ ! -z "$TMATE_SSH" ]; then
            break
        fi
        timeout=$((timeout+1))
    done

    cd "$dir"
    nohup qemu-system-x86_64 \
        -name "$RANDOM_ID" \
        -hda "$dir/$OS_IMG" \
        -m $RAM_VALUE \
        -smp ${CPU_CORES:-4} \
        -drive file=seed.img,format=raw \
        -nographic \
        -netdev user,id=net_$RANDOM_ID,net=10.0.2.0/24,dns=1.1.1.1,hostfwd=tcp::${TCP_HOST_PORT}-:${TCP_GUEST_PORT} \
        -device e1000,netdev=net_$RANDOM_ID > qemu_boot.log 2>&1 &

    clear
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "🎉              JKSOFT - VM NETWORK ACTIVE          "
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${WHITE}👤 Hostname   : ${CYAN}root@${RANDOM_ID}${NC}"
    echo -e "${WHITE}⚙️  Resources  : ${CYAN}${RAM_VALUE} RAM | ${CPU_CORES:-4} Cores${NC}"
    echo -e "${WHITE}🆔 NAT ID     : ${CYAN}${RANDOM_ID}${NC}"
    echo -e "${WHITE}🚀 Port Rule  : ${YELLOW}Host Port ${TCP_HOST_PORT} -> VM Port ${TCP_GUEST_PORT}${NC}"
    echo -e "${WHITE}📁 Path Root  : ${CYAN}${dir}${NC}"
    echo -e "${RED}----------------------------------------------------------${NC}"
    
    if [ ! -z "$TMATE_SSH" ]; then
        echo -e "${GREEN}✅ SSH BERHASIL REGENERASI !${NC}"
        echo ""
        echo -e "${WHITE}🔑 New SSH (No Password Needed) :${NC}"
        echo -e "${CYAN}$TMATE_SSH${NC}"
        echo ""
        echo -e "${YELLOW}⚠️ Old session sudah expired !${NC}"
    else
        echo -e "${RED}⚠️ Tunnel proxy tmate error / timeout dalam 10 detik. Gunakan fallback lokal.${NC}"
        echo -e "${WHITE}👉 Connection Command : ssh root@localhost -p ${TCP_HOST_PORT}${NC}"
    fi
    echo -e "${GREEN}==========================================================${NC}"
    echo ""
    echo -ne "${WHITE}Press [Enter] to return to Main Menu...${NC}"
    read
    show_menu
}

show_menu
