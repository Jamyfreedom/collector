if [ "$(id -u)" -ne 0 ]; then
    echo "Rerun script with sudo!"
    exit 1
fi

EIS_print_help() {
    echo "Usage: $0 [-h] [-d|-o <outdir>] -n <os>"
    echo ""
    echo "Options:"
    echo "    -h            Show this help message"
    echo "    -o <outdir>   Set output directory of this script to <outdir>"
    echo "    -d            Set output directory to same directory as script"
    echo "    -n <os>       Run script for <os>. '-n list' to show supported"
    echo ""
    echo "-n must be specified"
    echo "One of -o or -d must be provided"
    echo "But only one of -o and -d can be provided at once"
}

if [ $# -eq 0 ]; then
    EIS_print_help
    exit 0
fi

if command -v readlink >/dev/null 2>&1; then
    get_path="readlink -f"
elif command -v realpath >/dev/null 2>&1; then
    get_path="realpath -e"
fi

while getopts ho:dn: arg; do
    case "${arg}" in
        h )
            EIS_print_help
            exit 0
            ;;
        o )
            EIS_TMP_DIR_O="${OPTARG}"
            EIS_OUTPUT_DIR="$EIS_TMP_DIR_O"
            ;;
        d )
            EIS_TMP_DIR_D="$($get_path "$(dirname "$0")")"
            EIS_OUTPUT_DIR="$EIS_TMP_DIR_D"
            ;;
        n)
            EIS_OS_NAME="${OPTARG}"
            ;;
        * )
            echo "${OPTARG} not a recognised argument!"
            EIS_print_help
            exit 0
            ;;
    esac
done

echo ""
echo "================================================="
echo "Ensign NIX Artifact Collection and Triage (ENACT)"
echo "================================================="
echo ""

EIS_SCRIPT_DIR="$($get_path "$(dirname "$0")")"
EIS_TOOLS_DIR="$EIS_SCRIPT_DIR/tools"
EIS_SUPP_OS="$EIS_TOOLS_DIR/supported_os"

if [ "$EIS_OS_NAME" = "list" ]; then
    cat "$EIS_SUPP_OS"
    echo ""
    exit 0
elif [ -z  "$EIS_OS_NAME" ]; then
    echo "OS name is not set!"
    EIS_print_help
    exit 1
else
    if awk '{print $1}' "$EIS_SUPP_OS" | grep -q "\<$EIS_OS_NAME\>"; then
        EIS_VAR_FILE="$EIS_SCRIPT_DIR/osfiles/$EIS_OS_NAME.sh"
        . "$EIS_VAR_FILE" || { echo "Error sourcing var file." && exit 1; }
    else
        echo "$EIS_OS_NAME is not supported!"
        echo "Supported OSes: -"
        cat "$EIS_SUPP_OS"
        echo ""
        exit 1
    fi
fi

if [ -n "$EIS_TMP_DIR_O" ] && [ -n "$EIS_TMP_DIR_D" ]; then
    echo "Only one of -o and -d can be specified!"
    EIS_print_help
    exit 1
fi

EIS_OUTPUT_DIR="$($get_path "$EIS_OUTPUT_DIR")"

if [ ! -d "$EIS_OUTPUT_DIR" ]; then
    echo "$EIS_OUTPUT_DIR does not exist!"
    exit 1
fi

if (uname | grep -qi "sunos"); then
    echo "Solaris detected, will add to PATH variable to use POSIX binaries"
    PATH="/usr/xpg4/bin:$PATH"
fi

EIS_TARGET_NAME="$(hostname)_$(date +%Y%m%d_%H%M%S)"
EIS_TARGET_DIR="$EIS_OUTPUT_DIR/$EIS_TARGET_NAME"

mkdir "$EIS_TARGET_DIR" || { echo "Cannot create $EIS_TARGET_DIR" && exit 1; }
EIS_TARGET_DIR="$($get_path "$EIS_TARGET_DIR")"

EIS_CMD_DIR="$EIS_TARGET_DIR/EIS_cmd_output"
mkdir "$EIS_CMD_DIR"

EIS_LOG_FILE="$EIS_TARGET_DIR/EIS_general.log"

EIS_SECT_HEAD=""

copy() {
    dest="$(echo "$@" | awk '{print $NF}')"
    for i; do
        if [ "$i" = "$dest" ]; then
            break
        fi
        find "$i" -print -depth | cpio -pdmL "$dest"
        shift
    done >/dev/null 2>&1
}

log() {
    EIS_DATESTR="$(date "+%H:%M:%S %d/%m/%y")"
    EIS_WRITESTR="$EIS_DATESTR $EIS_SECT_HEAD $*"
    echo "$EIS_WRITESTR" | tee -a "$EIS_LOG_FILE"
}

EIS_RUN() {
    EIS_RUN_CMD="$1"
    EIS_OUT_FILE="$2"
    set -- "$EIS_RUN_CMD"
    if command -v "$(echo "$1" | cut -d ' ' -f 1)" >/dev/null 2>&1; then
        log "  = Running $EIS_RUN_CMD"
        if ! eval "$EIS_RUN_CMD" >> "$EIS_OUT_FILE" 2>&1; then
            log " ! '$EIS_RUN_CMD' command failed."
        fi
    else
        log " ~ '$EIS_RUN_CMD' not found. Not running."
    fi
}

EIS_COPY_FILES() {
    eval EIS_DEST_DIR="\$$#"
    pos=1
    for item in "$@"; do
        if [ $pos -eq $# ]; then
            break
        fi
        if [ -d "$item" ]; then
            echo "  = Copying $item $EIS_DEST_DIR"
            copy "$item" "$EIS_DEST_DIR"
        fi
        pos=$((pos + 1))
    done
}

EIS_SECT_HEAD="[ADMIN]"
log "Shell: $(ps -p $$ | tail -1 | awk '{print $NF}')"
log "Cmd args: $*"
log "Path ENV: $PATH"
log "Script dir: $EIS_SCRIPT_DIR"
log "Tools dir: $EIS_TOOLS_DIR"
log "Dest dir: $EIS_TARGET_DIR"
log "Current wd: $(pwd)"
log "Uptime: $(uptime)"
log "Var file: $EIS_VAR_FILE"

log "Temporarily changing \$PATH variable to allow more commands"
EIS_OLDPATH="$PATH"
PATH="$PATH:/sbin:/usr/sbin:/usr/local/sbin"

EIS_COLLECT_FS_INFO() {
    EIS_SECT_HEAD="[FILESYSTEM]"
    log "Collecting Filesystem artefacts."
    
    EIS_TSK_DIR="$EIS_TOOLS_DIR/tsk"
    
    EIS_RUN_ILS_FLS_MR() {
        EIS_RUN_DEV="$1"
        EIS_RUN_MNT="$2"
        EIS_RUN_FS="$3"
        EIS_FILE_APPEND="$(echo "$EIS_RUN_MNT" | sed 's/^\/$/_root/g;s/\//_/g')"

        EIS_TSK_OUT="$EIS_CMD_DIR/tsk"

        if [ ! -d "$EIS_TSK_OUT" ]; then
            mkdir "$EIS_TSK_OUT"
        fi
        
            
        
        EIS_MR_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
        if ! echo "$EIS_MR_OS" | grep -qiE 'Linux|SunOS'; then
            return
        fi

        EIS_MR_ARCH=""
        if uname -p | grep -qi '86'; then
            EIS_MR_ARCH="i386"
        elif uname -p | grep -qi 'sparc'; then
            EIS_MR_ARCH="sparc"
            return
        else
            return
        fi

        EIS_MR_EXE="mac-robber-$EIS_MR_OS-$EIS_MR_ARCH"

        log "- Collecting $EIS_RUN_MNT mac-robber output."

        EIS_OUT_FILE="$EIS_TSK_OUT/mac-robber$EIS_FILE_APPEND.out"
        EIS_MR_CMD="$EIS_TSK_DIR/$EIS_MR_EXE $EIS_RUN_MNT"
        EIS_RUN "$EIS_MR_CMD" "$EIS_OUT_FILE"
    }
    
    OLDIFS=$IFS
    IFS="
"
    log "- Inode and more detailed file system listing"
    mount_lines=$(mount -v | grep -if "$EIS_TOOLS_DIR/mount_fs")
    for mount_line in $mount_lines; do
        EIS_PATH_NAME="$(echo "$mount_line" | cut -d " " -f 1)"
        EIS_PATH_MNT="$(echo "$mount_line" | cut -d  " " -f 3)"
        EIS_PATH_FS="$(echo "$mount_line" | cut -d " " -f 5)"
        
        log "- Running for $EIS_PATH_MNT"
        EIS_RUN_ILS_FLS_MR "$EIS_PATH_NAME" "$EIS_PATH_MNT" "$EIS_PATH_FS"
    done
    IFS=$OLDIFS
    
    log "- Directory listing the universe."
    EIS_LS_DIR="$EIS_CMD_DIR/ls"
    mkdir "$EIS_LS_DIR"
    for topdir in /*; do
        log "  = Listing $topdir"
        find "$topdir" | xargs \
            stat -c "%i %A %h %U %G %s %x %y %z %N" >> "$EIS_LS_DIR/$topdir" 2>/dev/null
    done
    
    log "- Copying important directories."
    for copydir in $EIS_DIRS_TO_COPY; do
        log "  = Copying $copydir"
        copy "$copydir" "$EIS_TARGET_DIR"
    done
}

EIS_COLLECT_SYS_INFO() {
    EIS_SECT_HEAD="[SYSTEM]"
    log "Collecting system information"
    
    log "- Collecting system hostname"
    EIS_RUN "$EIS_SYS_HOSTNAME" "$EIS_CMD_DIR/hostname"
    
    log "- Collecting date and timezone"
    EIS_RUN "$EIS_SYS_DATETIME" "$EIS_CMD_DIR/date"
    
    log "- Collecting uptime"
    EIS_RUN "$EIS_SYS_UPTIME" "$EIS_CMD_DIR/uptime"
    
    log "- Collecting dmesg (running kernel messages)"
    EIS_RUN "$EIS_SYS_DMESG" "$EIS_CMD_DIR/dmesg"
    
    log "- Collecting kernel information"
    EIS_RUN "$EIS_SYS_UNAME" "$EIS_CMD_DIR/uname"
    
    log "- Collecting Endianness of CPU"
    EIS_RUN "$EIS_SYS_ENDIAN" "$EIS_CMD_DIR/endianness"
    
    log "- Collecting Journalctl live logs"
    EIS_RUN "$EIS_SYS_JOURNALCTL" "$EIS_CMD_DIR/journalctl"
    
    log "- Collecting running kernel modules"
    EIS_RUN "$EIS_SYS_LSMOD" "$EIS_CMD_DIR/lsmod"
    
    log "- Collecting running services using service"
    EIS_RUN "$EIS_SYS_SERVICE" "$EIS_CMD_DIR/service"
    
    log "- Collecting running services using systemd"
    EIS_RUN "$EIS_SYS_SYSTEMCTL" "$EIS_CMD_DIR/systemctl"

    log "- Collecting running services using chkconfig"
    EIS_RUN "$EIS_SYS_CHKCONFIG" "$EIS_CMD_DIR/chkconfig"
}

EIS_COLLECT_NET_INFO() {
    EIS_SECT_HEAD="[NETWORK]"
    log "Collecting Network artefacts."
    
    log "- Collecting network interface listing."
    EIS_RUN "$EIS_NET_IFCONFIG" "$EIS_CMD_DIR/ifconfig"
    
    log "- Collecting opened network ports using either netstat or ss"
    EIS_RUN "$EIS_NET_NETSTAT" "$EIS_CMD_DIR/netstat"
    
    log "- Collecting opened network ports using lsof"
    EIS_RUN "$EIS_NET_LSOF_I" "$EIS_CMD_DIR/lsof_i"
    
    log "- Collecting DHCP past leases"
    EIS_COPY_FILES "$EIS_NET_DHCP_LEASE_DIR" "$EIS_TARGET_DIR"
    
    log "- Collecting routing table using either route or ip route"
    EIS_RUN "$EIS_NET_ROUTE" "$EIS_CMD_DIR/route"
    
    log "- Collecting ARP neighbourhood details"
    EIS_RUN "$EIS_NET_ARP" "$EIS_CMD_DIR/arp"
    
    log "- Collecting Firewall configurations"
    EIS_RUN "$EIS_NET_FW" "$EIS_CMD_DIR/firewall"
}

EIS_COLLECT_APP_INFO() {
    EIS_SECT_HEAD="[PACKAGE]"
    log "Collecting Installed Applications"
    
    log "- Collecting package manager database of installed applications"
    EIS_RUN "$EIS_APP_LIST" "$EIS_CMD_DIR/installed_packages"
    
    log "- Verifying packages installed using builtin commands"
    EIS_RUN "$EIS_APP_VERIFY" "$EIS_CMD_DIR/verify_packages"
    
    log "- Collecting package manager history"
    EIS_RUN "$EIS_APP_HIST" "$EIS_CMD_DIR/pkg_man_history"
}

EIS_COLLECT_DEV_INFO() {
    EIS_SECT_HEAD="[DEVICES]"
    log "Collecting device information"
    
    log "- Collecting attached PCI(e) devices"
    EIS_RUN "$EIS_DEV_PCIE" "$EIS_CMD_DIR/lspci"
    
    log "- Collecting CPU info"
    EIS_RUN "$EIS_DEV_LSCPU" "$EIS_CMD_DIR/lscpu"
    
    log "- Collecting USB info"
    EIS_RUN "$EIS_DEV_LSUSB" "$EIS_CMD_DIR/lsusb"
    
    log "- Collecting mounted devices"
    EIS_RUN "$EIS_DEV_MOUNT" "$EIS_CMD_DIR/mount"
    
    log "- Collecting attached block devices (storage)"
    EIS_RUN "$EIS_DEV_BLK" "$EIS_CMD_DIR/lsblk"
    
    log "- Collecting filesystem usage statistics"
    EIS_RUN "$EIS_DEV_DF" "$EIS_CMD_DIR/df"
}

EIS_COLLECT_PS_INFO() {
    EIS_SECT_HEAD="[PROCESSES]"
    log "Collecting Running processes"
    
    log "- Collecting running processes using ps"
    EIS_RUN "$EIS_PROC_PS" "$EIS_CMD_DIR/ps"
    
    log "- Collecting running processes using pstree"
    EIS_RUN "$EIS_PROC_PSTREE" "$EIS_CMD_DIR/pstree"
    
    log "- Collecting running processes using top"
    EIS_RUN "$EIS_PROC_TOP" "$EIS_CMD_DIR/top"
    
    log "- Collecting opened file handles"
    EIS_RUN "$EIS_PROC_LSOF" "$EIS_CMD_DIR/lsof_files"
}

EIS_COLLECT_LOGIN_INFO() {
    EIS_SECT_HEAD="[LOGININFO]"
    log "Collecting login information"
    
    EIS_LAST_CMD() {
        for file in "$2"/$1; do
            EIS_DEST_FILENAME="$(echo "$file" | awk -F/ '{print $NF}')"
            EIS_DEST_FILE="$EIS_CMD_DIR/$EIS_DEST_FILENAME"
            EIS_LOGIN_CMD="$EIS_LOGIN_LAST \"$file\""
            EIS_RUN "$EIS_LOGIN_CMD" "$EIS_DEST_FILE"
        done
    }
    
    log "- Collecting who is logged in right now"
    EIS_RUN "$EIS_LOGIN_WHO" "$EIS_CMD_DIR/who"
    
    log "- Collecting wtmp in plaintext"
    EIS_LAST_CMD "wtmp*" "$EIS_LOGIN_WTMP_DIR"
    
    log "- Collecting btmp in plaintext"
    EIS_LAST_CMD "btmp*" "$EIS_LOGIN_BTMP_DIR"
    
    log "- Collecting utmp in plaintext"
    EIS_LAST_CMD "utmp*" "$EIS_LOGIN_UTMP_DIR"
    
    log "- Collecting lastlog in plaintext"
    EIS_RUN "$EIS_LOGIN_LASTLOG_CMD" "$EIS_CMD_DIR/lastlog"
    
    log "- Checking if we collected the actual lastlog file"
    if [ ! -f "$EIS_TARGET_DIR/$EIS_LOGIN_LASTLOG_FILE" ]; then
        EIS_COPY_FILES "$EIS_LOGIN_LASTLOG_FILE" "$EIS_TARGET_DIR"
    fi
}

EIS_COLLECT_USER_INFO() {
    EIS_SECT_HEAD="[USERINFO]"
    log "Collecting User related files"
    
    FIND_OUT_FILE="$EIS_CMD_DIR/find_errors"
    CPIO_CMD="cpio -pdmL \"$EIS_TARGET_DIR\""
    
    log "Copying all files ending with 'history' in user folders"
    EIS_COPY_FILES "/export/home/*/*history" "/home/*/*history" "/root/*history" "$EIS_TARGET_DIR"
    
    log "Copying all .ssh/ in user folders"
    EIS_COPY_FILES "/export/home/*/.ssh" "/home/*/.ssh" "/root/.ssh" "/.ssh" "$EIS_TARGET_DIR"
    
    log "Copying all .vnc/ in user folders"
    EIS_COPY_FILES "/export/home/*/.vnc*" "/home/*/.vnc*" "/root/.vnc*" "$EIS_TARGET_DIR"

    log "Copying all .profile files in user folders"
    EIS_COPY_FILES "/export/home/*/*profile" "/home/*/*profile" "/root/*profile" "$EIS_TARGET_DIR"

    log "Copying all rc files in user folders"
    EIS_COPY_FILES "/export/home/*/*rc" "/home/*/*rc" "/root/*rc" "$EIS_TARGET_DIR"
}

EIS_COLLECT_FILE_INFO() {
    EIS_SECT_HEAD="[FILEINFO]"
    log "Collecting Interesting Files"

    FIND_OUT_FILE="$EIS_CMD_DIR/find_errors"
    CPIO_CMD="cpio -pdmL \"$EIS_TARGET_DIR\""
    
    log "- Collecting md5 hashes of files in \$PATH"
    EIS_FILE_MD5="$EIS_CMD_DIR/md5sum_path_dirs"
    for path_dir in $(echo "$PATH" | tr ":" "\n"); do
        find "$path_dir" -type f -exec md5sum {} \; >> \
            "$EIS_FILE_MD5" 2>/dev/null
    done
    
    log "- Listing files ending with space"
    find / ! -path "/run/*" -a ! -path "/proc/*" -o \
         -iname ".* " | xargs \
            stat -c "%i %A %h %U %G %s %x %y %z %N" >> "$EIS_CMD_DIR/find_files_endswith_space"
    
    log "- Listing files with 777 permissions"
    find / ! -path "/run/*" -a ! -path "/proc/*" -o \
        -type f -o -type d -perm 777 | xargs \
            stat -c "%i %A %h %U %G %s %x %y %z %N" >> "$EIS_CMD_DIR/find_files_777"
    
    log "- Listing files with SetUID and SetGID"
    find / ! \( -path "/run/*" -o -path "/proc/*" \) -a \
        -type f -o -type d \( -perm -4000 -o -perm -2000 -o -perm -1000 \) | xargs \
            stat -c "%i %A %h %U %G %s %x %y %z %N" \
        > "$EIS_CMD_DIR/find_setuid_setgid_sticky"
    
    log "- Copying executable files in /tmp"
    EIS_FIND_CMD="find /tmp -type f \
        \( -perm -100 -o -perm -010 -o -perm -001 \) | $CPIO_CMD"
    EIS_RUN "$EIS_FIND_CMD" "$FIND_OUT_FILE"
    
    log "- Listing files with uncommon extensions on NIXes"
    find / ! -path "/run/*" -a ! -path "/proc/*" -a \
        -type f -iname ".*\.\(doc*\|ppt*\|xls*\|rar\|zip\|rtf\|exe\|dll\|\
        appimage\|dmg\|pdf\|scr\|vb[s]?\|jpeg\|jpg\|ht[am]*\|js\|jar\|sfx\|\
        bat\|tmp\|py*\|msi\|com\|msp\|cmd\|vbe\|jse\|ps*\|lnk\|inf\|scf\)"\
         | xargs \
            stat -c "%i %A %h %U %G %s %x %y %z %N" >> "$EIS_CMD_DIR/find_weird_ext"
}

EIS_COLLECT_EXT_INFO() {
    EIS_SECT_HEAD="[EXTERNAL]"
    log "Collecting using external applications"
    
    log "- Running vuls.io to get information in JSON format"
    EIS_RUN "$EIS_EXT_VULS \"$EIS_CMD_DIR\"" "$EIS_CMD_DIR/vuls"
    
    log "- Running chkrootkit to check for known rootkits"
    EIS_RUN "$EIS_EXT_CHKROOTKIT" "$EIS_CMD_DIR/chkrootkit"
}

EIS_TAR_THE_WORLD() {
    EIS_SECT_HEAD="[ADMIN]"
    
    log "Collection completed! TAR-ing the output"

    cd "$EIS_OUTPUT_DIR" || \
      { echo "Cannot change directory to $EIS_OUTPUT_DIR, TAR it manually." \
      && exit 1; }
    EIS_TAR_PATH="$EIS_OUTPUT_DIR/$EIS_TARGET_NAME.tar.gz"
    EIS_TAR_ERROR_FILE="/tmp/$EIS_TARGET_NAME.ERROR_TAR.log"
    EIS_TAR_CMD="tar -czf $EIS_TAR_PATH ./$EIS_TARGET_NAME"
    
    EIS_RUN "$EIS_TAR_CMD" "$EIS_TAR_ERROR_FILE"
    
    echo ""
    echo "TAR command completed."
    
    if [ -s "$EIS_TAR_ERROR_FILE" ]; then
        echo '!!! There were some errors in the tar process.'
        echo "View $EIS_TAR_ERROR_FILE for more details"
    else
        echo "No errors reported"
        rm "$EIS_TAR_ERROR_FILE"
    fi
}

EIS_COLLECT_FS_INFO
EIS_COLLECT_SYS_INFO
EIS_COLLECT_NET_INFO
EIS_COLLECT_APP_INFO
EIS_COLLECT_DEV_INFO
EIS_COLLECT_PS_INFO
EIS_COLLECT_LOGIN_INFO
EIS_COLLECT_USER_INFO
EIS_COLLECT_FILE_INFO
EIS_COLLECT_EXT_INFO
EIS_TAR_THE_WORLD

echo "Resetting \$PATH variable"
PATH="$EIS_OLDPATH"

echo ""
echo "All collection completed."
echo "Script Exiting."
