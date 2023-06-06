#!/bin/sh

#System info commands
EIS_SYS_HOSTNAME="hostname"
EIS_SYS_DATETIME="date -R"
EIS_SYS_UPTIME="uptime"
EIS_SYS_DMESG="dmesg"
EIS_SYS_UNAME="uname -a"
EIS_SYS_ENDIAN="$EIS_TOOLS_DIR/get-endianness.sh"
EIS_SYS_JOURNALCTL="journalctl -x"
EIS_SYS_LSMOD="lsmod"
EIS_SYS_SERVICE="service --status-all"
EIS_SYS_SYSTEMCTL="systemctl -al"

#Networking commands
EIS_NET_IFCONFIG="ip address"
EIS_NET_NETSTAT="ss -ap"
EIS_NET_LSOF_I="lsof -i"
EIS_NET_ROUTE="ip route"
EIS_NET_ARP="ip neighbour"
EIS_NET_FW="$EIS_TOOLS_DIR/iptables.sh"

#Package manager commands
EIS_APP_LIST="dpkg --list"
EIS_APP_VERIFY="dpkg -V"
EIS_APP_HIST=""

#External application commands
EIS_EXT_VULS="$EIS_TOOLS_DIR/vuls.sh"
EIS_EXT_CHKROOTKIT="$EIS_TOOLS_DIR/chkrootkit/chkrootkit"

#Device listing commands
EIS_DEV_PCIE="lspci -vvvnn"
EIS_DEV_LSCPU="lscpu"
EIS_DEV_LSUSB="lsusb"
EIS_DEV_MOUNT="mount"
EIS_DEV_BLK="lsblk"
EIS_DEV_DF="df -P"

#Process commands
EIS_PROC_PS="ps -ejHf"
EIS_PROC_PSTREE="pstree -paAl"
EIS_PROC_TOP="top -bcn1 -w512"
EIS_PROC_LSOF="lsof /"

#Login commands
EIS_LOGIN_WHO="who -a"
EIS_LOGIN_LAST="last -wFif"
EIS_LOGIN_WTMP_DIR="/var/log"
EIS_LOGIN_BTMP_DIR="/var/log"
EIS_LOGIN_UTMP_DIR="/var/run"
EIS_LOGIN_LASTLOG_FILE="/var/log/lastlog"
EIS_LOGIN_LASTLOG="lastlog"

#Some files to copy
EIS_DHCP_LEASE_DIR="/var/lib/dhcp /var/lib/NetworkManager"
EIS_DIRS_TO_COPY="/etc /var/log /var/spool /lib/systemd"

