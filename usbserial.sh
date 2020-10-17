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
	fi	

	if [ ${#HOST_NAME} -ne 0 ]; then
		cat<<EOF > $HOME/.screenrc
logfile "$HOME/screen_log/`date +%Y-%m-%dT%H%M%S+0900`-\$USER-`echo \$HOST_NAME`-serialconsole-diagnose.log"
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
logfile "$HOME/screen_log/`date +%Y-%m-%dT%H%M%S+0900`-\$USER-serialconsole-diagnose.log"
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
	
	case "$(uname)" in
		Linux)
			if ls /dev/ttyUSB*; [ $? -eq 0 ]; then
				screen -c "$HOME/.screenrc" -R -L $(ls -1 /dev/ttyUSB*) $BAUD_RATE
			else
				echo -e "No adequate usb serial device found. Connect your USB serial port and try again."
				exit 1
			fi
			;;
		*)
			if ls /dev/tty.usb*; [ $? -eq 0 ]; then
				screen -c "$HOME/.screenrc" -R -L $(ls -1 /dev/tty.usb*) $BAUD_RATE
			else
				TTYLIST="$(ls /dev/tty.*)"
				while IFS= read -r LINE; do
					TTYARRAY+=("$LINE")
				done < <$TTYLIST
				for TTYS in "${TTYARRAY[@]}"; do
					if [ -z "$(echo "$TTYS" | grep -iE 'bluetooth')" ]; then
						screen -c "$HOME/.screenrc" -R -L $TTYS $BAUD_RATE
					fi
				done
			fi
			;;
	esac
}

version () {
	echo -e "Breakfast-Serial v0.94.810-1\nA simple bash script for convenient USB Serial Console usage.\nWritten by Sidney Jeong, GNU GPL 3.0"
}

usage () {
	echo -e "Usage: usbserial.sh [options]\n\n-b|--baudrate [baudrate] Specifies the baud rate when you connect to the serial port. Mandatory option.\n-h|--hostname [hostname] Specifies the host name you would like to connect to. You can omit this option, but the script will make sure if you really want to leave the hostname blank.\n-v|--version Shows the version of the script.\n-h|--help|--usage Shows this help."
}

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

if [ -n $BAUD_RATE ]; then
	screentty
else
	exit 1
fi

