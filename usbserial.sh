#!/usr/bin/env bash

# USB serial port attachment script using GNU screen.
# Written by Sidney Jeong, GNU GPL 3.0.

unset HOST_NAME
unset CONTINUE
VERSION="0.94.810-7.70"

# Read function with null value support.
readnull () {
        local INPUTVALUE
        read -r INPUTVALUE
        if [ ${#INPUTVALUE} -eq 0 ]; then
                INPUTVALUE="NULL0"
        fi
        export $1=$INPUTVALUE
}

# Actually calls the screen.
callscreen () {
        local QMARK=1
        if [ $# -lt 2 ]; then
                local TTYUSB="$1"
        else
                local TTYUSB="$1 | $2"
        fi
        if eval $TTYUSB &> /dev/null; then
                local TTYUSB_ARRAY=( $(eval $TTYUSB) )
        else
                local TTYUSB_ARRAY=()
        fi
        local SELECTEDTTY="NULL1"
        case "${#TTYUSB_ARRAY[@]}" in
                0)
                        echo -e "No adequate usb serial device found. Connect your USB serial port and try again."
                        restorefile
                        exit 1
                        ;;
                1)
                        echo -e "Attaching to the screen..."
                        screen -c "$HOME/.screenrc" -R -L $(eval $TTYUSB | head -n 1) $BAUD_RATE; QMARK=$?
                        ;;
                *)
                        case "$TERM" in
                                xterm-color|*-256color)
                                        echo -e "More than one USB serial devices found.\nEnter desired device name and press [ENTER] \033[1;34m(Default=${TTYUSB_ARRAY[0]}).\033[00m\n\033[1;00mPossible input: \033[00m${TTYUSB_ARRAY[@]}"
                                        ;;
                                *)
                                        echo -e "More than one USB serial devices found.\nEnter desired device name and press [ENTER] (Default=${TTYUSB_ARRAY[0]}).\nPossible input: ${TTYUSB_ARRAY[@]}"
                                        ;;
                        esac
                        readnull SELECTEDTTY
                        while true; do
                                if [[ ${TTYUSB_ARRAY[@]} =~ "$SELECTEDTTY" ]]; then
                                        echo -e "Attaching to the screen..."
                                        screen -c "$HOME/.screenrc" -R -L $SELECTEDTTY $BAUD_RATE; QMARK=$?
                                        break
                                elif [ $SELECTEDTTY == "NULL0" ]; then
                                        echo -e "Attaching to the screen..."
                                        screen -c "$HOME/.screenrc" -R -L ${TTYUSB_ARRAY[0]} $BAUD_RATE; QMARK=$?
                                        break
                                else
                                        case "$TERM" in
                                                xterm-color|*-256color)
                                                        echo -e "\nUnknown choice. Press [ENTER] to select \033[1;34m${TTYUSB_ARRAY[0]}\033[00m or enter one of these possible inputs and press [ENTER]: ${TTYUSB_ARRAY[@]}"
                                                        ;;
                                                *)
                                                        echo -e "\nUnknown choice. Press [ENTER] to select ${TTYUSB_ARRAY[0]} or enter one of these possible inputs and press [ENTER]: ${TTYUSB_ARRAY[@]}"
                                                        ;;
                                        esac
                                        readnull SELECTEDTTY
                                fi
                        done
                        ;;
        esac
        return $QMARK
}

# Modifies the screenrc file and determines the conditions for calling the screen.
screentty () {
        # Checks if the log directory exists and if it doesn't, creates it.
        if [ -d $HOME/screen_log ]; then
                echo -e "The log directory exists. Continuing..."
        else
                echo -e "Creating the log directory..."
                mkdir -p $HOME/screen_log
        fi

        # Checks if the baud rate variable is null.
        if [ -z $BAUD_RATE ]; then
                echo -e "You must specify the baud rate. This is because the baud rate variable is unset or set to null."
                exit 1
        fi

        # Backs up current screenrc file
        if [ -f $HOME/.screenrc ]; then
                echo -e "Backing up current screenrc file...\n"
                cp -a $HOME/.screenrc $HOME/.screenrc.tmp
        fi

        # Checks if the host name is set and modifies the screenrc file.
        if [ ${#HOST_NAME} -ne 0 ]; then
                cat<<EOF > $HOME/.screenrc
logfile "$HOME/screen_log/`date +%Y-%m-%dT%H%M%S%z`-\$USER-`echo \$HOST_NAME`-serialconsole-diagnose.log"
logfile flush 1
logstamp off
log on
EOF
        else
                echo -e "You didn't enter the host name for your connected device. Continue? (Y/N):"
                read -r CONTINUE
                while true; do
                        case "$CONTINUE" in
                                Y|y|Yes|yes)
                                        cat<<EOF > $HOME/.screenrc
logfile "$HOME/screen_log/`date +%Y-%m-%dT%H%M%S%z`-\$USER-serialconsole-diagnose.log"
logfile flush 1
logstamp off
log on
EOF
                                        break
                                        ;;
                                N|n|No|no)
                                        restorefile
                                        exit 1
                                        ;;
                                *)
                                        echo -e "The input is wrong. Continue without connected device hostname (Y/N)?:"
                                        read -r CONTINUE
                                        ;;
                        esac
                done
        fi

        # Checks if the user is in dialout/dialer group (Some operating systems and distributions need the user to be in the group).
        local DIALOUT=$(grep -E '(dialout|dialer)' /etc/group | grep $USER | head -n 1)
        local DIALGNAME=$(grep -E '(dialout|dialer)' /etc/group | cut -d ':' -f 1 | head -n 1)
        local DIALGID=$(grep -E '(dialout|dialer)' /etc/group | cut -d ':' -f 3 | head -n 1)
        if [ ${#DIALOUT} -eq 0 ]; then
        echo -e "The current user is not found in $DIALGNAME group (GID $DIALGID).\nThe screen might not work as expected without sudo or adding the user to the group, logging out, and back in.\nPress [ENTER] to continue."
        read -r RETURN_KEY
        fi

        # Checks the operating system and calls the screen.
        case "$(uname)" in
                Linux)
                        callscreen "ls /dev/ttyUSB*" || echo -e "Screen terminated with an error. Check the screen log for details."
                        ;;
                Darwin)
                        callscreen "ls /dev/tty.usb*" "grep -vE 'blue'" || echo -e "Screen terminated with an error. Check the screen log for details."
                        ;;
                FreeBSD)
                        callscreen "ls /dev/ttyU*" "grep -vE '(init|lock)'" || echo -e " Screen terminated with an error. Check the screen log for details."
                        ;;
                *)
                        echo -e "This script doesn't support this type of operating system yet. Aborting."
                        restorefile
                        exit 1
                        ;;
        esac
}

# Prints the script version.
version () {
        echo -e "Breakfast-Serial v$VERSION\nA simple bash script for convenient USB Serial Console usage.\nWritten by Sidney Jeong, GNU GPL 3.0"
}

# Prints the usage.
usage () {
        case $TERM in
                xterm-color|*-256color)
                        echo -e "\033[1;33mUsage: bash usbserial.sh [options]\033[00m\n\n\033[1;37mOptions:\033[00m\n\033[1;34m-b|--baudrate \033[0;33m[baudrate] \033[00mSpecifies the baud rate when you connect to the serial port. If the option is not set, it defaults to 115200.\n\033[1;34m-h|--hostname \033[0;33m[hostname] \033[00mSpecifies the host name you would like to connect to. You can omit this option, but the script will make sure if you really want to leave the hostname blank.\n\033[1;34m-v|--version\033[00m Shows the version of the script.\n\033[1;34m--help|--usage \033[00mShows this help."
                        ;;
                *)
                        echo -e "Usage: bash usbserial.sh [options]\n\n-b|--baudrate [baudrate] Specifies the baud rate when you connect to the serial port. If this option is not set, it defaults to 115200.\n-h|--hostname [hostname] Specifies the host name you would like to connect to. You can omit this option, but the script will make sure if you really want to leave the hostname blank.\n-v|--version Shows the version of the script.\n--help|--usage Shows this help."
                        ;;
        esac
}

restorefile () {
        if mv $HOME/.screenrc.tmp $HOME/.screenrc; then
                echo -e "\nSuccessfully restored screen user configuration file."
                exit 0
        else
                echo -e "\nFailed to restore screen user configuration file. Please double-check the file."
                exit 1
        fi
}

BAUD_RATE=115200

while [ $# -gt 0 ]; do
        case "$1" in
                -h|--hostname)
                        if [ $# -gt 1 ] && [ $(echo "$2" | cut -c 1) != "-" ]; then
                                HOST_NAME=$2
                                shift
                        else
                                echo -e "Wrong or blank hostname specified.\nCheck your connected device hostname and retry."
                                exit 1
                        fi
                        shift
                        ;;
                -b|--baudrate)
                        if [ $# -gt 1 ] && [ "$2" -ge 72 ] && [ "$2" -le 256000 ] && [ $(echo "$2" | cut -c 1) != "-" ]; then
                                unset BAUD_RATE
                                BAUD_RATE=$2
                                shift
                        else
                                echo -e "Wrong or blank baud rate specified.\nCheck your input and retry."
                                exit 1
                        fi
                        shift
                        ;;
                -v|--version)
                        version
                        exit 0
                        ;;
                --help|--usage)
                        usage
                        exit 0
                        ;;
                *)
                        echo -e "Unknown option or argument -- $1\n"
                        usage
                        exit 1
                        ;;
        esac
done

screentty
restorefile
