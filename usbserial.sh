#!/usr/bin/env bash

unset HOST_NAME
unset BAUD_RATE
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
		screen -R -L $(ls -1 /dev/ttyUSB*) $BAUD_RATE
		exit 0
	fi	

	if [ -n $HOST_NAME ]; then
		cat << EOF > $HOME/.screenrc
		logfile "$HOME/screen_log/$(date +%Y%m%dT%H%M+0900)-$USER-$HOST_NAME-serialconsole-diagnose.log"
		logflie flush 1
		log on
EOF
	else
		echo -e "You didn't enter the host name for your connected device. Continue? (Y/N):"
		read $CONTINUE
		until [ 0 -eq 0 ]; do
			case "$CONTINUE" in
				Y|Yes|yes)
					cat << EOF > $HOME/.screenrc
					logfile "$HOME/screen_log/$(date +%Y%m%dT%H%M+0900)-$USER-serialconsole-diagnose.log"
					logfile flush 1
					log on
EOF
					break
					;;
				N|No|no)
					exit 1
					;;
				*)
					echo -e "The input is wrong. Continue without connected device hostname (Y/N)?:"
					read $CONTINUE
					;;
			esac
		done
	fi
}

version () {
	echo -e "Breakfast-Serial v0.94.810-1\nA simple bash script for convenient USB Serial Console usage.\nWritten by Sidney Jeong, GNU GPL 3.0"
}

usage () {
	echo -e "Usage: usbserial.sh [options]\n\n-b|--baudrate baudrate Specifies the baud rate when you connect to the serial port. Mandatory option.\n-h|--hostname [hostname] Specifies the host name you would like to connect to. You can omit this option, but the script will make sure if you really want to leave the hostname blank.\n-v|--version Shows the version of the script.\n-h|--help|--usage Shows this help."
}

while test $# -gt 0; do
	case "$1" in
		-h|--hostname)
			if test $# -gt 0; then
				export HOST_NAME=$2
				shift
			else
				echo -e "Wrong or blank hostname specified.\nCheck your connected device hostname and retry."
				exit 1
			fi
			shift
			;;
		-b|--baudrate)
			if test $# -gt 0 && [ "$2" -le 256000 ]; then
				export BAUD_RATE=$2
				shift
				screentty
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
if test $# -eq 0; then
	usage
	exit 1
fi
