
if [ "$(id -u)" -ne 0 ]; then
    echo "Rerun script with sudo!"
    exit 1
fi

print_help() {
    echo "Usage: $0 [-h] [ [-a] [-d | -o <path>] ]"
    echo ""
    echo "Options:"
    echo "  -h        Show this help message"
    echo "  -a        Run on autopilot mode"
    echo "  -o <path> Set output path to <path>"
    echo "  -d        Set output path to the same directory as the script"
    echo ""
    echo "If -a is not specified, -d and -o will be ignored"
    echo ""
    echo "= OUTPUT ="
    echo "Only one of -o or -d can be specified at once (both optional)."
    echo "If -o and -d are not specified, then output is set to the home"
    echo "directory of the running user."
    echo ""
    echo "= AUTOPILOT ="
    echo "Attempts to automatically pass arguments based on files in /etc."
    echo ""
    echo "= INTERACTIVE ="
    echo "Intractive mode currently incomplete. Functionally does nothing."
    echo ""
}

AUTOPILOT=0
OUTPUT_DEFAULT=0
OUTPUT_DIR=""

while getopts hao:d arg; do
    case "${arg}" in
        h )
            print_help
            exit 0
            ;;
        a )
            AUTOPILOT=1
            ;;
        o )
            OUTPUT_DEFAULT=0
            OUTPUT_DIR="${OPTARG}"
            ;;
        d )
            OUTPUT_DEFAULT=1
            ;;
        * )
            echo "${OPTARG} not a recognised argument!"
            print_help
            exit 0
            ;;
    esac
done

if [ -n "$OUTPUT_DIR" ] && [ $OUTPUT_DEFAULT -eq 1 ]; then
    echo "Only one of -o and -d can be specified at one time!"
    print_help
    exit 1
fi


if [ $AUTOPILOT -eq 0 ]; then
    OUTPUT_DEFAULT=0
    OUTPUT_DIR=""
fi

echo ""
echo "================================================================"
echo "Ensign NIX Triage Argument Insertion and Loader Script (ENTAILS)"
echo "================================================================"
echo ""

if (uname | grep -qi "sunos"); then
    echo "Solaris detected, will add to PATH variable to use POSIX binaries"
    PATH="/usr/xpg4/bin:$PATH"
fi

if [ $AUTOPILOT = 1 ]; then
    echo "ENTAILS started on AUTOPILOT mode"
    echo "Attempting to detect OS family and version"
    echo "Method 1: Using /etc/os-release file. Covers Linuxes and Solaris"

    RELEASE="/etc/os-release"
    OS_FAMILY=""
    OS_VERSION=""

    if [ -f "$RELEASE" ]; then
        UBUNTU="debian|ubuntu|raspbian"
        SOLARIS="solaris"
        SUSE="suse|sles|sled"
        RHEL="rhel|centos|amzn|ol|fedora|almalinux|clearos|rocky|scientific"

        ID="ID="
        VER="VERSION_ID="
        MAJOR_VER=""

        ID_FIELD="$(grep "$ID" "$RELEASE")"
        VER_FIELD="$(grep "$VER" "$RELEASE")"
        VER_ID="$(echo "$VER_FIELD" | cut -d "=" -f 2)"

        if (echo "$ID_FIELD" | grep -qiE "$UBUNTU"); then
            OS_FAMILY="ubuntu"
            MAJOR_VER="$(echo "$VER_ID" | cut -d"." -f 1 | \
                tr -d -c '[:digit:]')"

            DEB_VER_OS="debian|raspbian"
            UBUN_VER_OS="ubuntu"

            if (echo "$ID_FIELD" | grep -qiE "$DEB_VER_OS"); then
                if [ "$MAJOR_VER" -ge 9 ]; then
                    OS_VERSION="18"
                else
                    OS_VERSION="16"
                    echo "This version of Debian is nt supported yet"
                    exit 1
                fi
            elif (echo "$ID_FIELD" | grep -qiE "$UBUN_VER_OS"); then
                if [ "$MAJOR_VER" -ge 18 ]; then
                    OS_VERSION="18"
                else
                    OS_VERSION="16"
                    echo "This version of Ubuntu is nt supported yet"
                    exit 1
                fi
            fi
        elif (echo "$ID_FIELD" | grep -qiE "$SOLARIS"); then
            OS_FAMILY="solaris"
            MAJOR_VER="$(echo "$VER_ID" | cut -d"." -f 1 | \
                tr -d -c '[:digit:]')"
            if [ "$MAJOR_VER" -eq 11 ]; then
                OS_VERSION="11"
            elif [ "$MAJOR_VER" -eq 10 ]; then
                OS_VERSION="10"
                echo "This version of Solaris is not supported yet"
                exit 1
            else
                echo "This version of Solaris is not supported"
                exit 1
            fi
        elif (echo "$ID_FIELD" | grep -qiE "$SUSE"); then
            OS_FAMILY="suse"
            echo "SUSE is not supported by NIX Triage yet"
            exit 1
        elif (echo "$ID_FIELD" | grep -qiE "$RHEL"); then
            OS_FAMILY="rhel"
            MAJOR_VER="$(echo "$VER_ID" | cut -d"." -f 1 | \
                tr -d -c '[:digit:]')"

            RH_VER_OS="alma|centos|clearos|ol|rhel|scientific"
            AMZN_VER_OS="amzn"

            if (echo "$ID_FIELD" | grep -qiE "$RH_VER_OS"); then
                if [ "$MAJOR_VER" -ge 7 ]; then
                    OS_VERSION="7"
                else
                    OS_VERSION="6"
                    echo "This version of RHEL is not supported"
                    exit 1
                fi
            elif (echo "$ID_FIELD" | grep -qiE "$AMZN_VER_OS"); then
                if [ "$MAJOR_VER" -eq 2 ]; then
                    OS_VERSION="7"
                elif [ "$MAJOR_VER" -eq 2018 ]; then
                    OS_VERSION="6"
                    echo "This version of RHEL is not supported"
                    exit 1
                fi
            fi
        fi
    fi
    
    if [ -z $OS_FAMILY ]; then
        echo "Method 1 failed. Probably not a Linux or Solaris system"
        echo "Method 2: Brute force commands. Covers AIX"
        if (command -v oslevel); then
            OS_FAMILY="aix"
            OSLEVEL_MAJOR="$(oslevel | cut -d "." -f 1 \
                tr -d -c '[:digit:]')"
            if [ "$OSLEVEL_MAJOR" -eq 6 ]; then
                OS_VERSION="6"
            elif [ "$OSLEVEL_MAJOR" -eq 7 ]; then
                OS_VERSION="$(oslevel | cut -d "." -f 1,2 \
                tr -d -c '[:digit:]')"
            fi
        elif (command -v machinfo); then
            OS_FAMILY="hpux"
            echo "HP-UX is not supported by NIX Triage"
            exit 1
        else
            echo "Method 3: uname -s output. Reserved for future use"
            OS_FAMILY="$(uname -s)"
            echo "$OS_FAMILY is not supported by NIX Triage"
            exit 1
        fi
    fi

    echo "Success!"
    OS_SCRIPT_NAME="$OS_FAMILY$OS_VERSION"

    echo "Using $OS_SCRIPT_NAME to run collector.sh"

    SCRIPT_DIR="$(dirname "$(realpath -e "$0")")"

    if [ -z "$OUTPUT_DIR" ] && [ $OUTPUT_DEFAULT -eq 0 ]; then
        echo "-o and -d not specified. Defaulting to home directory of running user."

        RUN_USER="$(who | awk '{print $1}' | head -1)"
        DEST_DIR="$(grep "^$RUN_USER:" /etc/passwd | cut -d":" -f 6)"

        echo "Running command:-"
        echo "sh $SCRIPT_DIR/collector.sh -o $DEST_DIR -n $OS_SCRIPT_NAME"
        echo ""

        sh "$SCRIPT_DIR/collector.sh" -o "$DEST_DIR" -n "$OS_SCRIPT_NAME"

    elif [ -z "$OUTPUT_DIR" ] && [ $OUTPUT_DEFAULT -eq 1 ]; then
        echo "-d specified. Outputting to the same directory as script."

        echo "Running command:-"
        echo "sh $SCRIPT_DIR/collector.sh -d -n $OS_SCRIPT_NAME"
        echo ""

        sh "$SCRIPT_DIR/collector.sh" -d -n "$OS_SCRIPT_NAME"

    else
        echo "-o specified. Will create output directory if not exists."
        if [ ! -d "$OUTPUT_DIR" ]; then
            mkdir -p "$OUTPUT_DIR"
        fi
        sh "$SCRIPT_DIR/collector.sh" -o "$OUTPUT_DIR" -n "$OS_SCRIPT_NAME"
    fi
fi

true << EOF
else
    echo "ENTAILS will interactively prompt you for your inputs for NIX Triage"
    echo "Press [Ctrl+C] at any point to exit"
    echo "No files will be touched until the final prompt"
    echo ""
    echo "Press [Enter] to Begin"
    read -r this

    echo "\$this"
    clear

    while true; do
        echo "Key in the number of your server's OS and press [Enter]: -"
        echo "   [1] Ubuntu 14.04 LTS or earlier"
        echo "   [2] Ubuntu 16.04 LTS or later"
        echo "   [3] Debian 7 or earlier"
        echo "   [4] Debian 8 or later"
        echo "   [5] CentOS/RHEL 6 or earlier"
        echo "   [6] CentOS/RHEL 7 or later"
        echo "   [7] SLES Linux 12 or earlier"
        echo "   [8] SLES Linux 15 or later"
        echo "   [9] Solaris 10.x"
        echo "  [10] Solaris 11.x"
        read -r SERVER_OS_NUM
        
        if ! echo "\$SERVER_OS_NUM" | grep -qE "^[0-9]+$" || \
            [ "\$SERVER_OS_NUM" -lt 1 ] || [ "\$SERVER_OS_NUM" -gt 10 ]; then
            echo "That is not a valid option"
            echo ""
            continue
        fi
        
        echo ""
        break
    done

    case \$SERVER_OS_NUM in
        1 )
            SERVER_OS="ubuntu14"
            ;;
        2 )
            SERVER_OS="ubuntu16"
            ;;
        3 )
            SERVER_OS="debian7"
            ;;
        4 )
            SERVER_OS="debian8"
            ;;
        5 )
            SERVER_OS="rhel6"
            ;;
        6 )
            SERVER_OS="rhel7"
            ;;
        7 )
            SERVER_OS="sles12"
            ;;
        8 )
            SERVER_OS="sles15"
            ;;
        9 )
            SERVER_OS="solaris10"
            ;;
        10 )
            SERVER_OS="solaris11"
            ;;
        * )
            echo "Invalid OS!"
            exit 1
            ;;
    esac

    echo "You have chosen \$SERVER_OS"

    while true; do
        echo "Enter a destination folder to store the output (must exist)"
        read -r DEST_DIR
        
        DEST_DIR="\$(readlink -e "\$DEST_DIR")"
        if [ ! -d "\$DEST_DIR" ]; then
            echo "Directory entered does not exist!"
            echo ""
            continue
        fi
        
        echo ""
        break
    done

    echo "Target dir: \$DEST_DIR"
fi
EOF