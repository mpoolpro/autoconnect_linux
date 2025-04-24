#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${GREEN}
███╗░░░███╗██████╗░░█████╗░░█████╗░██╗░░░░░░░░██████╗░██████╗░░█████╗░
████╗░████║██╔══██╗██╔══██╗██╔══██╗██║░░░░░░░░██╔══██╗██╔══██╗██╔══██╗
██╔████╔██║██████╔╝██║░░██║██║░░██║██║░░░░░░░░██████╔╝██████╔╝██║░░██║
██║╚██╔╝██║██╔═══╝░██║░░██║██║░░██║██║░░░░░░░░██╔═══╝░██╔══██╗██║░░██║
██║░╚═╝░██║██║░░░░░╚█████╔╝╚█████╔╝███████╗██╗██║░░░░░██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝╚═╝░░░░░░╚════╝░░╚════╝░╚══════╝╚═╝╚═╝░░░░░╚═╝░░╚═╝░╚════╝░
${NC}"
echo -e "${BLUE}=== Official MPool.pro XMR Auto-Miner ===${NC}\n"

if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}[!] Please run as root or use sudo!${NC}"
  exit 1
fi

ARCH=$(uname -m)
if [[ "$ARCH" == *"arm"* ]] || [[ "$ARCH" == *"aarch"* ]]; then
  echo -e "${RED}[!] ARM architecture detected!${NC}"
  echo -e "${YELLOW}[!] Sorry, this script supports only x86_64 CPUs${NC}"
  echo -e "${YELLOW}[!] Please use desktop/laptop or server with Intel/AMD processor${NC}"
  exit 1
fi

while true; do
  read -p "$(echo -e "${YELLOW}[?] Enter your Monero wallet address: ${NC}")" wallet
  if [[ $wallet =~ ^4[0-9A-Za-z]{94}$|^8[0-9A-Za-z]{94}$|^4[0-9A-Za-z]{105}$|^8[0-9A-Za-z]{105}$ ]]; then
    break
  else
    echo -e "${RED}[!] Invalid Monero wallet address format!${NC}"
  fi
done

echo -e "\n${BLUE}[*] System detection...${NC}"
if [ -f /etc/debian_version ]; then
  echo -e "${GREEN}[+] Debian/Ubuntu detected${NC}"
  apt update && apt upgrade -y
  apt install -y wget tar sudo screen
elif [ -f /etc/redhat-release ]; then
  echo -e "${GREEN}[+] Red Hat/CentOS detected${NC}"
  yum update -y
  yum install -y epel-release
  yum config-manager --set-enabled epel
  yum install -y wget tar sudo
  
  if ! yum install -y screen; then
    echo -e "${YELLOW}[!] 'screen' not found in default repos. Trying to install from source...${NC}"
    cd /tmp
    yum install -y gcc make ncurses-devel
    curl -LO https://ftp.gnu.org/gnu/screen/screen-4.9.1.tar.gz
    tar -xzf screen-4.9.1.tar.gz
    cd screen-4.9.1
    ./configure && make && make install
    ln -s /usr/local/bin/screen /usr/bin/screen
  fi
elif [ -f /etc/arch-release ]; then
  echo -e "${GREEN}[+] Arch Linux detected${NC}"
  pacman -Syu --noconfirm
  pacman -S wget tar sudo screen --noconfirm
else
  echo -e "${YELLOW}[!] Unknown distribution, trying to continue...${NC}"
fi

if ! command -v screen &> /dev/null; then
  echo -e "${RED}[!] Screen not installed! Please install it manually${NC}"
  exit 1
fi

echo -e "\n${BLUE}[*] Downloading XMRig...${NC}"
wget https://github.com/xmrig/xmrig/releases/download/v6.17.0/xmrig-6.17.0-linux-x64.tar.gz -q --show-progress

echo -e "\n${BLUE}[*] Installing XMRig...${NC}"
tar -xzf xmrig-6.17.0-linux-x64.tar.gz
mkdir -p mpool_xmrig
mv xmrig-6.17.0/* mpool_xmrig/
rm -rf xmrig-6.17.0*

echo -e "\n${GREEN}[+] Installation complete! Launching miner in screen in 7 seconds...${NC}"
cd mpool_xmrig

echo -e "${YELLOW}===================================================${NC}"
echo -e "${BLUE} To detach from screen session: ${NC}"
echo -e "${GREEN} Press ${RED}Ctrl+A${GREEN} followed by ${RED}D${NC}"
echo -e "${YELLOW}===================================================${NC}\n"

sleep 7

screen -S mpool_miner -dm ./xmrig -o pool.mpool.pro:4242 -u $wallet -p monero -a rx/0 -k --tls
screen -r mpool_miner

echo -e "\n${BLUE}[!] Miner continues running in background.${NC}"
echo -e "${GREEN} To reconnect: ${YELLOW}screen -r mpool_miner${NC}"
echo -e "${GREEN} To list sessions: ${YELLOW}screen -ls${NC}\n"
