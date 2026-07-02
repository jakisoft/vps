#!/bin/bash

clear

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================================${NC}"
echo -e "${GREEN}    👹 JKSoft - E2B SANDBOX TERMINAL LAUNCHER 👹          ${NC}"
echo -e "${CYAN}==========================================================${NC}"
echo ""

if [ -z "$E2B_API_KEY" ]; then
    echo -e "${YELLOW}👉 Masukkan E2B API Key Anda:${NC}"
    echo -ne "${CYAN}🔑 API Key: ${NC}"
    read -s E2B_API_KEY
    echo ""
fi

if [ -z "$E2B_API_KEY" ]; then
    echo -e "${RED}❌ API Key tidak boleh kosong! Proses dibatalkan.${NC}"
    exit 1
fi

export E2B_API_KEY=$E2B_API_KEY

if ! command -v npx &> /dev/null; then
    echo -e "${RED}❌ Error: 'npx' (Node.js) diperlukan di mesin lokal.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}==========================================================${NC}"
echo -e "🚀 Membuat E2B Sandbox..."
echo -e "${GREEN}==========================================================${NC}"
echo ""

npx -y @e2b/code-interpreter@latest node -e "
const { CodeInterpreter } = require('@e2b/code-interpreter');

async function run() {
  try {
    const sandbox = await CodeInterpreter.create();
    console.log('✅ Sandbox berhasil dibuat dengan ID:', sandbox.sandboxId);
    
    const exec = await sandbox.commands.run('bash -c \"echo \\\"Memulai shell di sandbox...\\\" && bash\"');
    
    console.log('\n${GREEN}🤖 Output Sandbox:${NC}\n', exec.stdout);
    if(exec.stderr) console.error('${RED}⚠️ Stderr:${NC}', exec.stderr);

    await sandbox.close();
  } catch (error) {
    console.error('${RED}❌ Terjadi kesalahan:${NC}', error);
  }
}

run();
"

echo ""
echo -e "${YELLOW}👋 Sesi E2B telah diputus. Kembali ke terminal lokal.${NC}"
