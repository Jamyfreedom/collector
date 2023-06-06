#!/bin/sh

#System info commands
EIS_SYS_HOSTNAME="hostname"
EIS_SYS_DATETIME="date -R"
EIS_SYS_UPTIME="uptime"
EIS_SYS_DMESG="errpt -a"
EIS_SYS_UNAME="uname -a"
EIS_SYS_ENDIAN="$EIS_TOOLS_DIR/get-endianness.sh"
EIS_SYS_JOURNALCTL=""
EIS_SYS_LSMOD="genkex"
EIS_SYS_SERVICE="lssrc -l -s inetd"
EIS_SYS_SYSTEMCTL="lssrc -a"
EIS_SYS_SYSLEVEL="oslevel"

#Networking commands
EIS_NET_IFCONFIG="ifconfig -a"
EIS_NET_NETSTAT="netstat -an"
EIS_NET_LSOF_I="lsof -i"
EIS_NET_ROUTE="route -n"
EIS_NET_ARP="arp"
EIS_NET_FW=""

#Package manager commands
EIS_APP_LIST="lslpp"
EIS_APP_VERIFY="rpm -Va"
EIS_APP_HIST=""

#External application commands
EIS_EXT_VULS="$EIS_TOOLS_DIR/vuls.sh"
EIS_EXT_CHKROOTKIT="$EIS_TOOLS_DIR/chkrootkit/chkrootkit"

#Device listing commands
EIS_DEV_PCIE="lsdev -P -H"
EIS_DEV_LSCPU="prtconf -v"
EIS_DEV_LSUSB="lsdev -s usb"
EIS_DEV_MOUNT="mount -v"
EIS_DEV_BLK=""
EIS_DEV_DF="df -P"

#Process commands
EIS_PROC_PS="ps -AfT 0"
EIS_PROC_PSTREE="pstree"
EIS_PROC_TOP="proctree -aT"
EIS_PROC_LSOF="lsof"

#Login commands
EIS_LOGIN_WHO=""
EIS_LOGIN_LAST="last -Xf"
EIS_LOGIN_WTMP_FILE="/var/log/wtmp*"
EIS_LOGIN_UTMP_FILE="/etc/utmp*"
EIS_LOGIN_BTMP_FILE="/etc/security/failedlogin*"
EIS_LOGIN_LASTLOG_FILE="/etc/security/lastlog"
EIS_LOGIN_LASTLOG_CMD="lastlog"

#Some files to copy
EIS_DHCP_LEASE_DIR=""
EIS_DIRS_TO_COPY="/etc /var/adm /var/sadm /var/log /var/spool"

