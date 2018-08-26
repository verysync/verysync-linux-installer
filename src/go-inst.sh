#!/bin/bash

# This file is accessible as https://install.direct/go.sh

# If not specify, default meaning of return value:
# 0: Success
# 1: System error
# 2: Application error
# 3: Network error

CUR_VER=""
NEW_VER=""
ARCH=""
VDIS="amd64"
ZIPFILE="/tmp/verysync/verysync.zip"
VERYSYNC_RUNNING=0

CMD_INSTALL=""
CMD_UPDATE=""
SOFTWARE_UPDATED=0

SYSTEMCTL_CMD=$(command -v systemctl 2>/dev/null)
SERVICE_CMD=$(command -v service 2>/dev/null)

CHECK=""
FORCE=""
HELP=""
VSHOME=""

#######color code########
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message


#########################
while [[ $# > 0 ]];do
    key="$1"
    case $key in
        -p|--proxy)
        PROXY="-x ${2}"
        shift # past argument
        ;;
        -h|--help)
        HELP="1"
        ;;
        -f|--force)
        FORCE="1"
        ;;
        -c|--check)
        CHECK="1"
        ;;
        --remove)
        REMOVE="1"
        ;;
        --version)
        VERSION="$2"
        shift
        ;;
        -l|--local)
        LOCAL="$2"
        LOCAL_INSTALL="1"
        shift
        ;;
        -d|--home)
        VSHOME="$2"
        shift
        ;;
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done

###############################
colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

sysArch(){
    ARCH=$(uname -m)
    if [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
        VDIS="i386"
    elif [[ "$ARCH" == *"armv7"* ]] || [[ "$ARCH" == "armv6l" ]]; then
        VDIS="arm"
    elif [[ "$ARCH" == *"armv8"* ]] || [[ "$ARCH" == "aarch64" ]]; then
        VDIS="arm64"
    elif [[ "$ARCH" == *"mips64le"* ]]; then
        VDIS="mips64le"
    elif [[ "$ARCH" == *"mips64"* ]]; then
        VDIS="mips64"
    elif [[ "$ARCH" == *"mipsle"* ]]; then
        VDIS="mipsle"
    elif [[ "$ARCH" == *"mips"* ]]; then
        VDIS="mips"
    elif [[ "$ARCH" == *"s390x"* ]]; then
        VDIS="s390x"
    fi
    return 0
}

downloadVerysync(){
    rm -rf /tmp/verysync
    mkdir -p /tmp/verysync
    colorEcho ${BLUE} "Downloading verysync."
    DOWNLOAD_LINK="https://github.com/verysync/releases/releases/download/${NEW_VER}/verysync-linux-${VDIS}-${NEW_VER}.tar.gz"
    curl ${PROXY} -L -H "Cache-Control: no-cache" -o ${ZIPFILE} ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        colorEcho ${RED} "Failed to download! Please check your network or try again."
        return 3
    fi
    return 0
}

installSoftware(){
    COMPONENT=$1
    if [[ -n `command -v $COMPONENT` ]]; then
        return 0
    fi

    getPMT
    if [[ $? -eq 1 ]]; then
        colorEcho ${RED} "The system package manager tool isn't APT or YUM, please install ${COMPONENT} manually."
        return 1
    fi
    if [[ $SOFTWARE_UPDATED -eq 0 ]]; then
        colorEcho ${BLUE} "Updating software repo"
        $CMD_UPDATE
        SOFTWARE_UPDATED=1
    fi

    colorEcho ${BLUE} "Installing ${COMPONENT}"
    $CMD_INSTALL $COMPONENT
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to install ${COMPONENT}. Please install it manually."
        return 1
    fi
    return 0
}

# return 1: not apt, yum, or zypper
getPMT(){
    if [[ -n `command -v apt-get` ]];then
        CMD_INSTALL="apt-get -y -qq install"
        CMD_UPDATE="apt-get -qq update"
    elif [[ -n `command -v yum` ]]; then
        CMD_INSTALL="yum -y -q install"
        CMD_UPDATE="yum -q makecache"
    elif [[ -n `command -v zypper` ]]; then
        CMD_INSTALL="zypper -y install"
        CMD_UPDATE="zypper ref"
    else
        return 1
    fi
    return 0
}


extract(){
    colorEcho ${BLUE}"Extracting verysync package to /tmp/verysync."
    mkdir -p /tmp/verysync
    tar xzf $1 -C "/tmp/verysync/"
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to extract verysync."
        return 2
    fi
    return 0
}


# 1: new verysync. 0: no. 2: not installed. 3: check failed. 4: don't check.
getVersion(){
    if [[ -n "$VERSION" ]]; then
        NEW_VER="$VERSION"
        return 4
    else
        VER=`/usr/bin/verysync/verysync -version 2>/dev/null`
        RETVAL="$?"
        CUR_VER=`echo $VER | head -n 1 | cut -d " " -f2`
        #TAG_URL="https://api.github.com/repos/verysync/releases/releases/latest"
        TAG_URL="https://upgrades.verysync.cn/meta.json"
        NEW_VER=`curl ${PROXY} -k -s ${TAG_URL} --connect-timeout 10| grep 'tag_name' | cut -d\" -f4`
        if [[ $? -ne 0 ]] || [[ $NEW_VER == "" ]]; then
            colorEcho ${RED} "Failed to fetch release information. Please check your network or try again."
            return 3
        elif [[ $RETVAL -ne 0 ]];then
            return 2
        elif [[ "$NEW_VER" != "$CUR_VER" ]];then
            return 1
        fi
        return 0
    fi
}

stopVerysync(){
    colorEcho ${BLUE} "Shutting down verysync service."
    if [[ -n "${SYSTEMCTL_CMD}" ]] || [[ -f "/lib/systemd/system/verysync.service" ]] || [[ -f "/etc/systemd/system/verysync.service" ]]; then
        ${SYSTEMCTL_CMD} stop verysync
    elif [[ -n "${SERVICE_CMD}" ]] || [[ -f "/etc/init.d/verysync" ]]; then
        ${SERVICE_CMD} verysync stop
    fi
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to shutdown verysync service."
        return 2
    fi
    return 0
}

startVerysync(){
    if [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/lib/systemd/system/verysync.service" ]; then
        ${SYSTEMCTL_CMD} start verysync
    elif [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/etc/systemd/system/verysync.service" ]; then
        ${SYSTEMCTL_CMD} start verysync
    elif [ -n "${SERVICE_CMD}" ] && [ -f "/etc/init.d/verysync" ]; then
        ${SERVICE_CMD} verysync start
    fi
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to start verysync service."
        return 2
    fi
    return 0
}

copyFile() {
    NAME=$1
    ERROR=`cp "/tmp/verysync/verysync-linux-${VDIS}-${NEW_VER}/${NAME}" "/usr/bin/verysync/${NAME}" 2>&1`
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "${ERROR}"
        return 1
    fi
    return 0
}

makeExecutable() {
    chmod +x "/usr/bin/verysync/$1"
}

installVerysync(){
    # Install verysync binary to /usr/bin/verysync
    if [[ -f /usr/bin/verysnc ]]; then
        rm -rf /usr/bin/verysync
    fi
    mkdir -p /usr/bin/verysync
    copyFile verysync
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to copy verysync binary and resources."
        return 1
    fi
    makeExecutable verysync

    # Install verysync server config to /etc/verysync
    # if [[ ! -f "/etc/verysync/config.json" ]]; then
    #     mkdir -p /etc/verysync
    #     mkdir -p /var/log/verysync
    #     cp "/tmp/verysync/verysync-${NEW_VER}-linux-${VDIS}/vpoint_vmess_freedom.json" "/etc/verysync/config.json"
    #     if [[ $? -ne 0 ]]; then
    #         colorEcho ${YELLOW} "Failed to create verysync configuration file. Please create it manually."
    #         return 1
    #     fi
    #     let PORT=$RANDOM+10000
    #     UUID=$(cat /proc/sys/kernel/random/uuid)
    #
    #     sed -i "s/10086/${PORT}/g" "/etc/verysync/config.json"
    #     sed -i "s/23ad6b10-8d1a-40f7-8ad0-e3e35cd38297/${UUID}/g" "/etc/verysync/config.json"
    #
    #     colorEcho ${BLUE} "PORT:${PORT}"
    #     colorEcho ${BLUE} "UUID:${UUID}"
    # fi
    # return 0
}


installInitScript(){
    if [[ -n "${SYSTEMCTL_CMD}" ]];then
        if [[ ! -f "/etc/systemd/system/verysync.service" ]]; then
            if [[ ! -f "/lib/systemd/system/verysync.service" ]]; then
                #cp "/tmp/verysync/verysync-linux-${VDIS}-${NEW_VER}/etc/linux-systemd/system/verysync.service" "/etc/systemd/system/"
                cp "etc/linux-systemd/system/verysync.service" "/etc/systemd/system/"
                if [[ -n "$VSHOME" ]]; then
                    sed -i "s#__VSHOME_HOLDER__#-home \"$VSHOME\"#" /etc/systemd/system/verysync.service
                else
                    sed -i "s/__VSHOME_HOLDER__//" /etc/systemd/system/verysync.service
                fi
                systemctl enable verysync.service
                systemctl start verysync.service
            fi
        fi
        return
    elif [[ -n "${SERVICE_CMD}" ]] && [[ ! -f "/etc/init.d/verysync" ]]; then
        # installSoftware "daemon"
        # installSoftware "daemon" || return $?
        # cp "/tmp/verysync/verysync-linux-${VDIS}-${NEW_VER}/etc/linux-systemv/verysync" "/etc/init.d/verysync"
        
        # if [[ $? -ne 0 ]]; then
        # fi
        
        if [[ -n `command -v chkconfig` ]]; then
            #Centos
            if [[ ! -f "start-stop-daemon/$VDIS" ]]; then
                installSoftware "daemon" || return $?
            else
                cp "start-stop-daemon/$VDIS" /usr/bin/verysync/start-stop-daemon
                chmod +x /usr/bin/verysync/start-stop-daemon
            fi

            cp "etc/linux-init.d/verysync" "/etc/init.d/verysync"
            chmod +x "/etc/init.d/verysync"

            if [[ -n "$VSHOME" ]]; then
                sed -i "s#^VSHOME=#VSHOME=\"$VSHOME\"#" /etc/systemd/system/verysync.service
            fi

            
            chkconfig --add verysync
            service verysync start
        elif [[ -n `command -v update-rc.d` ]]; then
            #Debian/Centos
            installSoftware "daemon" || return $?

            cp "etc/linux-systemv/verysync" "/etc/init.d/verysync"
            chmod +x "/etc/init.d/verysync"

            if [[ -n "$VSHOME" ]]; then
                sed -i "s#^VSHOME=#VSHOME=\"$VSHOME\"#" /etc/systemd/system/verysync.service
            fi

            update-rc.d verysync defaults
        fi
    fi
    return
}

Help(){
    echo "./go-installer.sh [-h] [-c] [--remove] [-p proxy] [-f] [--version vx.y.z] [-l file] [-d index location]"
    echo "  -h, --help            Show help"
    echo "  -p, --proxy           To download through a proxy server, use -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128 etc"
    echo "  -f, --force           Force install"
    echo "      --version         Install a particular version, use --version v3.15"
    echo "  -l, --local           Install from a local file"
    echo "      --remove          Remove installed verysync"
    echo "  -c, --check           Check for update"
    echo "  -d  --home            Verysync index data location, default ~/.config/verysync"
    return 0
}

remove(){
    if [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/etc/systemd/system/verysync.service" ]];then
        if pgrep "verysync" > /dev/null ; then
            stopVerysync
        fi
        systemctl disable verysync.service
        rm -rf "/usr/bin/verysync" "/etc/systemd/system/verysync.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove verysync."
            return 0
        else
            colorEcho ${GREEN} "Removed verysync successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    elif [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/lib/systemd/system/verysync.service" ]];then
        if pgrep "verysync" > /dev/null ; then
            stopVerysync
        fi
        systemctl disable verysync.service
        rm -rf "/usr/bin/verysync/verysync" "/lib/systemd/system/verysync.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove verysync."
            return 0
        else
            colorEcho ${GREEN} "Removed verysync successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    elif [[ -n "${SERVICE_CMD}" ]] && [[ -f "/etc/init.d/verysync" ]]; then
        if pgrep "verysync" > /dev/null ; then
            stopVerysync
        fi
        rm -rf "/usr/bin/verysync" "/etc/init.d/verysync"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove verysync."
            return 0
        else
            colorEcho ${GREEN} "Removed verysync successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    else
        colorEcho ${YELLOW} "verysync not found."
        return 0
    fi
}

checkUpdate(){
    echo "Checking for update."
    VERSION=""
    getVersion
    RETVAL="$?"
    if [[ $RETVAL -eq 1 ]]; then
        colorEcho ${BLUE} "Found new version ${NEW_VER} for verysync.(Current version:$CUR_VER)"
    elif [[ $RETVAL -eq 0 ]]; then
        colorEcho ${BLUE} "No new version. Current version is ${NEW_VER}."
    elif [[ $RETVAL -eq 2 ]]; then
        colorEcho ${YELLOW} "No verysync installed."
        colorEcho ${BLUE} "The newest version for verysync is ${NEW_VER}."
    fi
    return 0
}

main(){
    #helping information
    [[ "$HELP" == "1" ]] && Help && return
    [[ "$CHECK" == "1" ]] && checkUpdate && return
    [[ "$REMOVE" == "1" ]] && remove && return

    [[ -n "$VSHOME" && -f "$VSHOME" ]] && colorEcho {$RED} "$VSHOME is not directory path" && return

    if [[  -n "$VSHOME" && ! -d "$VSHOME" ]]; then
        mkdir -p "$VSHOME"
        if [[ $? -ne 0 ]]; then
            colorEcho {$RED}  "create $VSHOME fails"
            return 1
        fi
    fi
    
    

    sysArch
    # extract local file
    if [[ $LOCAL_INSTALL -eq 1 ]]; then
        echo "Installing verysync via local file"
        installSoftware unzip || return $?
        rm -rf /tmp/verysync
        extract $LOCAL || return $?
        FILEVDIS=`ls /tmp/verysync |grep "verysync-linux-${VDIS}-v" |cut -d "-" -f3`
        SYSTEM=`ls /tmp/verysync |grep "verysync-linux-${VDIS}-v" |cut -d "-" -f2`
        if [[ ${SYSTEM} != "linux" ]]; then
            colorEcho ${RED} "The local verysync can not be installed in linux."
            return 1
        elif [[ ${FILEVDIS} != ${VDIS} ]]; then
            colorEcho ${RED} "The local verysync can not be installed in ${ARCH} system."
            return 1
        else
            NEW_VER=`ls /tmp/verysync |grep "verysync-linux-${VDIS}-v" |cut -d "-" -f4,5`
        fi
    else
        # download via network and extract
        installSoftware "curl" || return $?
        getVersion
        RETVAL="$?"
        if [[ $RETVAL == 0 ]] && [[ "$FORCE" != "1" ]]; then
            colorEcho ${BLUE} "Latest version ${NEW_VER} is already installed."
            return
        elif [[ $RETVAL == 3 ]]; then
            return 3
        else
            colorEcho ${BLUE} "Installing verysync ${NEW_VER} on ${ARCH}"
            downloadVerysync || return $?
            installSoftware unzip || return $?
            extract ${ZIPFILE} || return $?
        fi
    fi
    if pgrep "verysync" > /dev/null ; then
        VERYSYNC_RUNNING=1
        stopVerysync
    fi
    installVerysync || return $?
    installInitScript || return $?
    if [[ ${VERYSYNC_RUNNING} -eq 1 ]];then
        colorEcho ${BLUE} "Restarting verysync service."
        startVerysync
    fi
    colorEcho ${GREEN} "Verysync ${NEW_VER} is installed."
    rm -rf /tmp/verysync
    return 0
}

main
