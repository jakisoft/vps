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
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[===      ]"
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

$SUDO_CMD mkdir -p /home/nat/cache > /dev/null 2>&1

show_menu() {
    clear
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}          [👹 JKSOFT PREMIUM VPS DASHBOARD 👹]           ${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo ""
    echo -e "${YELLOW}👉 SELECT AN OPTION TO PROCEED FROM LIST:${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Create & Boot New NAT VPS Instance"
    echo -e "  ${CYAN}[2]${NC} List VM NAT Active Instance"
    echo -e "  ${CYAN}[3]${NC} Configuration & VM Management Panel"
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
    echo -e "${WHITE}⚙️  CREATE NEW VIRTUAL MACHINE NAT${NC}"
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
            OS_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
            OS_IMG="ubuntu22.qcow2"
            ;;
    esac

    echo ""
    echo -ne "${BLUE}🔹 Enter RAM Size in GB (e.g., 4, 8, 16): ${NC}"
    read RAM_GB
    RAM_GB=${RAM_GB:-4}
    echo -ne "${BLUE}🔹 Enter CPU Cores (e.g., 2, 4, 8): ${NC}"
    read CPU_CORES
    CPU_CORES=${CPU_CORES:-2}
    echo -ne "${BLUE}🔹 Enter Disk Space to ADD in GB (e.g., 10, 20): ${NC}"
    read DISK_ADD
    DISK_ADD=${DISK_ADD:-10}
    echo -ne "${BLUE}🔹 Enter Custom External Host Port (e.g., 2222, 5000): ${NC}"
    read TCP_HOST_PORT
    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    
    USER_PASS="1234"
    TCP_GUEST_PORT=22
    RANDOM_ID=$(tr -dc 'a-z0-9' < /dev/urandom | head -c 10)
    VM_DIR="/home/nat/$RANDOM_ID"

    echo ""
    echo -e "${YELLOW}⏳ Injecting Core High-Speed Network Drivers... Please wait.${NC}"
    echo ""
    
    $SUDO_CMD apt-get update -y > /dev/null 2>&1
    $SUDO_CMD apt-get install -y qemu-system-x86 qemu-utils wget cloud-image-utils curl tmate openssh-client > /dev/null 2>&1
    
    $SUDO_CMD mkdir -p "$VM_DIR" > /dev/null 2>&1
    
    if [ ! -f "/home/nat/cache/$OS_IMG" ]; then
        echo -e "${YELLOW}📥 Downloading Cloud Image to /home/nat/cache/...${NC}"
        $SUDO_CMD wget -q --show-progress "$OS_URL" -O /home/nat/cache/$OS_IMG
        $SUDO_CMD chmod 666 /home/nat/cache/$OS_IMG
    fi

    $SUDO_CMD cp "/home/nat/cache/$OS_IMG" "$VM_DIR/$OS_IMG"
    $SUDO_CMD chmod 666 "$VM_DIR/$OS_IMG"
    
    loading_bar "Generating Cloud-Init Matrix"
    
    cat <<'EOF' > /tmp/user-data
#cloud-config
ssh_pwauth: True
chpasswd:
  list: |
    root:1234
  expire: False
packages:
  - curl
  - wget
  - tmux
  - tmate
write_files:
  - path: /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf
    content: |
      [Service]
      ExecStart=
      ExecStart=-/sbin/agetty --autologin root --keep-baud 115200,38400,9600 %I $TERM
  - path: /root/start_tmate.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      sleep 15
      for i in {1..30}; do
        tmate -S /tmp/tmate.sock new-session -d
        tmate -S /tmp/tmate.sock wait tmate-ready
        TMATE_SSH=$(tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}')
        if [ -n "$TMATE_SSH" ]; then
          echo "$TMATE_SSH" > /dev/ttyS1
          break
        fi
        sleep 5
      done
runcmd:
  - sed -i 's|#\?\s*\(PermitRootLogin\).*|\1 yes|g' /etc/ssh/sshd_config
  - sed -i 's|#\?\s*\(PasswordAuthentication\).*|\1 yes|g' /etc/ssh/sshd_config
  - echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
  - echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
  - systemctl daemon-reload
  - systemctl restart sshd
  - systemctl restart serial-getty@ttyS0.service
  - bash /root/start_tmate.sh &
EOF

    sed -i "s/ssh_pwauth: True/ssh_pwauth: True\nhostname: $RANDOM_ID\nmanage_etc_hosts: true/" /tmp/user-data

    $SUDO_CMD cloud-localds "$VM_DIR/seed.img" /tmp/user-data > /dev/null 2>&1
    rm -f /tmp/user-data

    loading_bar "Expanding Server Hard Disk Allocation"
    $SUDO_CMD qemu-img resize "$VM_DIR/$OS_IMG" +${DISK_ADD}G > /dev/null 2>&1
    
    save_env "$RANDOM_ID" "$RAM_GB" "$CPU_CORES" "$USER_PASS" "$TCP_HOST_PORT" "$TCP_GUEST_PORT" "$OS_IMG"
    boot_qemu "$RANDOM_ID"
}

save_env() {
    local target_id="$1"
    local target_ram="$2"
    local target_cpu="$3"
    local target_pass="$4"
    local target_hport="$5"
    local target_gport="$6"
    local target_img="$7"
    
    local target_dir="/home/nat/$target_id"
    $SUDO_CMD mkdir -p "$target_dir"
    
    echo "RAM_GB=$target_ram" | $SUDO_CMD tee "$target_dir/vps.env" > /dev/null
    echo "CPU_CORES=$target_cpu" | $SUDO_CMD tee -a "$target_dir/vps.env" > /dev/null
    echo "USER_PASS=$target_pass" | $SUDO_CMD tee -a "$target_dir/vps.env" > /dev/null
    echo "TCP_HOST_PORT=$target_hport" | $SUDO_CMD tee -a "$target_dir/vps.env" > /dev/null
    echo "TCP_GUEST_PORT=$target_gport" | $SUDO_CMD tee -a "$target_dir/vps.env" > /dev/null
    echo "OS_IMG=$target_img" | $SUDO_CMD tee -a "$target_dir/vps.env" > /dev/null
    echo "RANDOM_ID=$target_id" | $SUDO_CMD tee -a "$target_dir/vps.env" > /dev/null
}

is_running() {
    local target_id="$1"
    if [ -f "/home/nat/$target_id/qemu.pid" ]; then
        local pid=$(cat "/home/nat/$target_id/qemu.pid")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

stop_vm() {
    local target_id="$1"
    if [ -f "/home/nat/$target_id/qemu.pid" ]; then
        local pid=$(cat "/home/nat/$target_id/qemu.pid")
        $SUDO_CMD kill "$pid" 2>/dev/null
        sleep 2
        if kill -0 "$pid" 2>/dev/null; then
            $SUDO_CMD kill -9 "$pid" 2>/dev/null
        fi
        $SUDO_CMD rm -f "/home/nat/$target_id/qemu.pid"
    fi
}

boot_qemu() {
    local target_id="$1"
    local target_dir="/home/nat/$target_id"
    
    if [ -f "$target_dir/vps.env" ]; then
        source "$target_dir/vps.env"
    fi

    stop_vm "$target_id"
    
    $SUDO_CMD rm -f "$target_dir/tmate.txt"
    $SUDO_CMD touch "$target_dir/tmate.txt"
    $SUDO_CMD chmod 666 "$target_dir/tmate.txt"

    clear
    echo -e "${GREEN}==========================================================${NC}"
    type_effect "👹 DATA SYSTEM SYNCHRONIZED! PIPING TERMINAL CHANNELS..." 0.02
    echo -e "${GREEN}==========================================================${NC}"
    echo ""

    $SUDO_CMD qemu-system-x86_64 \
        -hda "$target_dir/$OS_IMG" \
        -m "${RAM_GB}G" \
        -smp "${CPU_CORES}" \
        -drive file="$target_dir/seed.img,format=raw" \
        -nographic \
        -netdev user,id=net0,net=10.0.2.0/24,dns=1.1.1.1,hostfwd=tcp::${TCP_HOST_PORT}-:${TCP_GUEST_PORT} \
        -device e1000,netdev=net0 \
        -serial null \
        -serial file:"$target_dir/tmate.txt" \
        -daemonize \
        -pidfile "$target_dir/qemu.pid"

    local tmate_ssh=""
    for ((i=0; i<60; i++)); do
        if [ -s "$target_dir/tmate.txt" ]; then
            tmate_ssh=$(cat "$target_dir/tmate.txt" | tr -d '\r' | tr -d '\n')
            if [[ "$tmate_ssh" == *"ssh "* ]]; then
                break
            fi
        fi
        echo -ne "\r⌛ Menunggu koneksi tmate SSH di generate di dalam VM... ($((60-i))s) "
        sleep 2
    done
    echo ""

    clear
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "🎉             JKSOFT - VM NETWORK ACTIVE                 "
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${WHITE}👤 Username   : ${CYAN}root${NC}"
    echo -e "${WHITE}🔑 Password   : ${CYAN}${USER_PASS:-1234}${NC}"
    echo -e "${WHITE}⚙️ Resources  : ${CYAN}${RAM_GB}G RAM | ${CPU_CORES} Cores${NC}"
    echo -e "${WHITE}🆔 Hostname/ID : ${CYAN}${target_id}${NC}"
    echo -e "${WHITE}🚀 Port Forward: ${YELLOW}Host Port ${TCP_HOST_PORT} -> VM Port ${TCP_GUEST_PORT}${NC}"
    echo -e "${RED}----------------------------------------------------------${NC}"
    
    if [ -n "$tmate_ssh" ]; then
        echo -e "${GREEN}✅ SSH BERHASIL DIGENERATE DI DALAM VM!${NC}"
        echo ""
        echo -e "${WHITE}🔑 Tmate SSH :${NC}"
        echo -e "${CYAN}$tmate_ssh${NC}"
        echo ""
    else
        echo -e "${RED}⚠️ Gagal mendapatkan tunnel tmate dari dalam VM.${NC}"
        echo -e "${WHITE}👉 Connection Fallback : ssh root@localhost -p ${TCP_HOST_PORT}${NC}"
    fi
    echo -e "${GREEN}==========================================================${NC}"
    echo ""
    echo -ne "${WHITE}Tekan [Enter] untuk kembali ke menu utama...${NC}"
    read
    show_menu
}

list_vm() {
    clear
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "📋            JKSOFT - ACTIVE NAT VM LIST                 "
    echo -e "${GREEN}==========================================================${NC}"
    echo ""
    
    local found=0
    for d in /home/nat/*; do
        if [ -d "$d" ] && [ -f "$d/vps.env" ]; then
            found=1
            local vm_id=$(basename "$d")
            source "$d/vps.env"
            
            local status="${RED}STOPPED${NC}"
            if is_running "$vm_id"; then
                status="${GREEN}RUNNING${NC}"
            fi
            
            echo -e "🆔 VM Host ID : ${CYAN}${vm_id}${NC} [$status]"
            echo -e "💿 OS Image   : ${CYAN}${OS_IMG}${NC}"
            echo -e "⚙️  Resources  : ${CYAN}${RAM_GB}G RAM | ${CPU_CORES} Cores${NC}"
            echo -e "🚀 Port Rule  : ${YELLOW}Host Port ${TCP_HOST_PORT} -> VM Port ${TCP_GUEST_PORT}${NC}"
            if [ -s "$d/tmate.txt" ]; then
                local link=$(cat "$d/tmate.txt" | tr -d '\r' | tr -d '\n')
                echo -e "🔑 Tmate SSH  : ${GREEN}${link}${NC}"
            fi
            echo -e "${RED}----------------------------------------------------------${NC}"
        fi
    done

    if [ $found -eq 0 ]; then
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
    echo -e "${WHITE}⚙️🛠️  JKSOFT CONFIGURATION & MANAGEMENT PANEL${NC}"
    echo -e "${YELLOW}==========================================================${NC}"
    echo ""
    
    local vms=()
    local count=1
    for d in /home/nat/*; do
        if [ -d "$d" ] && [ -f "$d/vps.env" ]; then
            vms+=($(basename "$d"))
            local status="${RED}STOPPED${NC}"
            if is_running "$(basename "$d")"; then
                status="${GREEN}RUNNING${NC}"
            fi
            echo -e "  ${CYAN}[$count]${NC} VM ID: $(basename "$d") [$status]"
            count=$((count+1))
        fi
    done

    if [ ${#vms[@]} -eq 0 ]; then
        echo -e "${RED}❌ No VMs available to manage.${NC}"
        echo ""
        echo -ne "${WHITE}Press [Enter] to return to menu...${NC}"
        read
        show_menu
        return
    fi

    echo -e "  ${CYAN}[$count]${NC} Back to Main Menu"
    echo ""
    echo -e "${YELLOW}==========================================================${NC}"
    echo -ne "${WHITE}🔹 Choose VM Index [1-$count]: ${NC}"
    read INDEX_CHOICE

    if [ "$INDEX_CHOICE" -eq "$count" ]; then
        show_menu
        return
    fi

    if [ "$INDEX_CHOICE" -ge 1 ] && [ "$INDEX_CHOICE" -lt "$count" ]; then
        local selected_id="${vms[$((INDEX_CHOICE-1))]}"
        vm_sub_menu "$selected_id"
    else
        echo -e "${RED}❌ Invalid Choice!${NC}"
        sleep 2
        config_panel
    fi
}

vm_sub_menu() {
    local vm_id="$1"
    local vm_dir="/home/nat/$vm_id"
    
    while true; do
        if [ -f "$vm_dir/vps.env" ]; then
            source "$vm_dir/vps.env"
        fi

        local status="${RED}STOPPED${NC}"
        if is_running "$vm_id"; then
            status="${GREEN}RUNNING${NC}"
        fi

        clear
        echo -e "${YELLOW}==========================================================${NC}"
        echo -e "${WHITE}🛠️  MANAGING VM: ${CYAN}$vm_id${NC} [$status]${NC}"
        echo -e "${YELLOW}==========================================================${NC}"
        echo ""
        echo -e "Specs: RAM ${CYAN}${RAM_GB}G${NC} | CPU ${CYAN}${CPU_CORES} Cores${NC} | Port ${CYAN}${TCP_HOST_PORT}${NC}"
        echo ""
        echo -e "  ${CYAN}[1]${NC} Update VM Specs (RAM, CPU, Add Disk, Host Port)"
        echo -e "  ${CYAN}[2]${NC} Regenerate tmate SSH Session (Reboots VM)"
        echo -e "  ${CYAN}[3]${NC} Delete / Wipe VM Instance"
        echo -e "  ${CYAN}[4]${NC} Back to VM Selection List"
        echo ""
        echo -e "${YELLOW}==========================================================${NC}"
        echo -ne "${WHITE}🔹 Enter Choice [1-4]: ${NC}"
        read SUB_CHOICE

        case $SUB_CHOICE in
            1)
                update_vm_spec "$vm_id"
                ;;
            2)
                regenerate_ssh "$vm_id"
                ;;
            3)
                delete_vm "$vm_id"
                return
                ;;
            4)
                config_panel
                return
                ;;
            *)
                echo -e "${RED}❌ Invalid Choice!${NC}"
                sleep 1
                ;;
        esac
    done
}

update_vm_spec() {
    local vm_id="$1"
    local vm_dir="/home/nat/$vm_id"
    
    source "$vm_dir/vps.env"
    
    clear
    echo -e "${YELLOW}==========================================================${NC}"
    echo -e "${WHITE}⚙️  UPDATE VM RESOURCES CONFIGURATION: $vm_id${NC}"
    echo -e "${YELLOW}==========================================================${NC}"
    echo ""
    
    echo -ne "${BLUE}🔹 Enter NEW RAM Size in GB (Leave empty to keep $RAM_GB): ${NC}"
    read NEW_RAM
    RAM_GB=${NEW_RAM:-$RAM_GB}
    
    echo -ne "${BLUE}🔹 Enter NEW CPU Cores (Leave empty to keep $CPU_CORES): ${NC}"
    read NEW_CPU
    CPU_CORES=${NEW_CPU:-$CPU_CORES}
    
    echo -ne "${BLUE}🔹 Enter NEW Disk Space to ADD in GB (Leave empty/0 to skip): ${NC}"
    read NEW_DISK
    NEW_DISK=${NEW_DISK:-0}
    
    echo -ne "${BLUE}🔹 Enter NEW Custom External Host Port (Leave empty to keep $TCP_HOST_PORT): ${NC}"
    read NEW_PORT
    TCP_HOST_PORT=${NEW_PORT:-$TCP_HOST_PORT}
    
    stop_vm "$vm_id"
    
    if [ "$NEW_DISK" -gt 0 ]; then
        loading_bar "Expanding Server Hard Disk Allocation"
        $SUDO_CMD qemu-img resize "$vm_dir/$OS_IMG" +${NEW_DISK}G > /dev/null 2>&1
    fi
    
    save_env "$vm_id" "$RAM_GB" "$CPU_CORES" "$USER_PASS" "$TCP_HOST_PORT" "$TCP_GUEST_PORT" "$OS_IMG"
    
    echo -e "${GREEN}✅ Resources successfully updated! Booting machine...${NC}"
    sleep 2
    boot_qemu "$vm_id"
}

regenerate_ssh() {
    local vm_id="$1"
    echo -e "${YELLOW}🔄 Regenerating tmate session tunnels by restarting VM...${NC}"
    sleep 1
    boot_qemu "$vm_id"
}

delete_vm() {
    local vm_id="$1"
    local vm_dir="/home/nat/$vm_id"
    
    clear
    echo -e "${RED}⚠️  WARNING: You are about to permanently delete VM $vm_id !${NC}"
    echo -ne "${WHITE}Are you sure? (y/n): ${NC}"
    read CONFIRM
    
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        stop_vm "$vm_id"
        $SUDO_CMD rm -rf "$vm_dir"
        echo -e "${GREEN}✅ VM $vm_id successfully wiped!${NC}"
        sleep 2
        config_panel
    fi
}

show_menu
