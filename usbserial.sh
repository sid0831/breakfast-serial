#!/usr/bin/env bash

unset HOST_NAME
unset CONTINUE

screentty () {
	if [ -d $HOME/screen_log ]; then
		echo -e "The log directory exists. Continuing..."
	else
		echo -e "Creating the log directory..."
		mkdir -p $HOME/screen_log
	fi
	if [ -z $BAUD_RATE ]; then
		echo -e "You must specify the baud rate."
		exit 1
	else
		echo -e "Attaching to the screen..."
	fi	

	if [ ${#HOST_NAME} -ne 0 ]; then
		cat<<EOF > $HOME/.screenrc
logfile "$HOME/screen_log/`date +%Y-%m-%dT%H%M%S%z`-\$USER-`echo \$HOST_NAME`-serialconsole-diagnose.log"
logfile flush 1
logstamp on
log on
EOF
	else
		echo -e "You didn't enter the host name for your connected device. Continue? (Y/N):"
		read CONTINUE
		while [ 0 -eq 0 ]; do
			case "$CONTINUE" in
				Y|y|Yes|yes)
					cat<<EOF > $HOME/.screenrc
logfile "$HOME/screen_log/`date +%Y-%m-%dT%H%M%S%z`-\$USER-serialconsole-diagnose.log"
logfile flush 1
logstamp on
log on
EOF
					break
					;;
				N|n|No|no)
					exit 1
					;;
				*)
					echo -e "The input is wrong. Continue without connected device hostname (Y/N)?:"
					read CONTINUE
					;;
			esac
		done
	fi
	
	DIALOUT=$(cat /etc/group | grep dialout | grep $USER)
	DIALGID=$(cat /etc/group | grep dialout | cut -d ':' -f 3)
	if [ ${#DIALOUT} -eq 0 ]; then
        echo -e "The current user is not found in dialout group (GID $DIALGID).\nThe screen might not work as expected without sudo or adding the user to the group, logging out, and back in.\nPress [ENTER] to continue."
        read RETURN_KEY
    fi
	
	case "$(uname)" in
		Linux)
			if ls /dev/ttyUSB*; [ $? -eq 0 ]; then
				screen -c "$HOME/.screenrc" -R -L $(ls -1 /dev/ttyUSB*) $BAUD_RATE
			else
				echo -e "No adequate usb serial device found. Connect your USB serial port and try again."
				exit 1
			fi
			;;
		Darwin)
			if ls /dev/tty.usb*; [ $? -eq 0 ]; then
				screen -c "$HOME/.screenrc" -R -L $(ls -1 /dev/tty.usb*) $BAUD_RATE
			else
				echo -e "No adequate usb serial device found. Connect your USB serial port and try again."
				exit 1
			fi
			;;
        FreeBSD)
            if ls /dev/ttyU*; [ $? -eq 0 ]; then
                screen -c "$HOME/.screenrc" -R -L $(ls /dev/ttyU* | cut -d ' ' -f 1 | head -n 1) $BAUD_RATE
            else
                echo -e "No adequate usb serial device found. Connect your USB serial port and try again."
                exit 1
            fi
            ;;
        *)
            echo -e "This script doesn't support this type of operating system yet. Aborting."
            exit 1
            ;;
	esac
}

version () {
	echo -e "Breakfast-Serial v0.94.810-1\nA simple bash script for convenient USB Serial Console usage.\nWritten by Sidney Jeong, GNU GPL 3.0"
}

usage () {
	echo -e "Usage: usbserial.sh [options]\n\n-b|--baudrate [baudrate] Specifies the baud rate when you connect to the serial port. If this option is not set, it defaults to 115200.\n-h|--hostname [hostname] Specifies the host name you would like to connect to. You can omit this option, but the script will make sure if you really want to leave the hostname blank.\n-v|--version Shows the version of the script.\n-h|--help|--usage Shows this help."
}

BAUD_RATE=115200

while test $# -gt 0; do
	case "$1" in
		-h|--hostname)
			if test $# -gt 0; then
				HOST_NAME=$2
				shift
			else
				echo -e "Wrong or blank hostname specified.\nCheck your connected device hostname and retry."
				exit 1
			fi
			shift
			;;
		-b|--baudrate)
			if test $# -gt 0 && [ "$2" -le 256000 ]; then
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
			shift
			;;
		*)
			usage
			exit 1
			shift
			;;
	esac
done

screentty
