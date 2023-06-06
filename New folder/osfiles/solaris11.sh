#!/bin/sh

#System info commands
EIS_SYS_HOSTNAME="hostname"
EIS_SYS_DATETIME="date"
EIS_SYS_UPTIME="uptime"
EIS_SYS_DMESG="dmesg"
EIS_SYS_UNAME="uname -a"
EIS_SYS_ENDIAN="$EIS_TOOLS_DIR/get-endianness.sh"
EIS_SYS_JOURNALCTL=""
EIS_SYS_LSMOD="modinfo -c"
EIS_SYS_SERVICE="svcs -a"
EIS_SYS_SYSTEMCTL=""

#Networking commands
EIS_NET_IFCONFIG="ifconfig -a"
EIS_NET_NETSTAT="netstat -an"
EIS_NET_LSOF_I="lsof -i"
EIS_NET_ROUTE="netstat -r"
EIS_NET_ARP="arp -a"
EIS_NET_FW=""

#Package manager commands
EIS_APP_LIST="pkginfo"
EIS_APP_VERIFY="pkg verify"
EIS_APP_HIST="pkg history"

#External application commands
EIS_EXT_VULS="$EIS_TOOLS_DIR/vuls.sh"
EIS_EXT_CHKROOTKIT="$EIS_TOOLS_DIR/chkrootkit/chkrootkit"

#Device listing commands
EIS_DEV_PCIE="cfgadm pci"
EIS_DEV_LSCPU="isainfo -v"
EIS_DEV_LSUSB="cfgadm usb"
EIS_DEV_MOUNT="mount"
EIS_DEV_BLK="df -b"
EIS_DEV_DF="df -n"

#Process commands
EIS_PROC_PS="ps -ejHf"
EIS_PROC_PSTREE="ptree -a 0"
EIS_PROC_TOP="top -bcn"
EIS_PROC_LSOF="pfiles /proc/*"

#Login commands
EIS_LOGIN_WHO="who -a"
EIS_LOGIN_LAST="last -f"
EIS_LOGIN_WTMP_DIR="/var/adm"
EIS_LOGIN_BTMP_DIR="/var/adm"
EIS_LOGIN_UTMP_DIR="/var/run"
EIS_LOGIN_LASTLOG_FILE="/var/adm/lastlog"
EIS_LOGIN_LASTLOG=""

#Some files to copy
EIS_DHCP_LEASE_DIR=""
EIS_DIRS_TO_COPY="/etc /var/log /var/adm /var/sadm"

