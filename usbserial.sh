#!/usr/bin/env bash

unset HOST_NAME
unset CONTINUE
unset SELECTEDTTY

# Read function with null value support.
readnull () {
        local INPUTVALUE
        read INPUTVALUE
        if [ ${#INPUTVALUE} -eq 0 ]; then
                INPUTVALUE="NULL0"
        fi
        export $1=$INPUTVALUE
}

# Actually calls the screen.
callscreen () {
	local TTYUSB="$1"
	local QMARK=1
	if $TTYUSB > /dev/null; [ $? -eq 0 ]; then
        	TTYUSB_LC=$($TTYUSB | wc -l | sed 's/[ \t]//g')
        else
                TTYUSB_LC=0
        fi
        case "$TTYUSB_LC" in
                0)
                        echo -e "No adequate usb serial device found. Connect your USB serial port and try again."
                        exit 1
                        ;;
                1)
                        echo -e "Attaching to the screen..."
                        screen -c "$HOME/.screenrc" -R -L $($TTYUSB | head -n 1) $BAUD_RATE; QMARK=$?
                        ;;
        	*)
			if [ ${BASH_VERSINFO[0]} -lt 4 ]; then
				echo -e "Bash 4 is more than $(( $(date +%Y) - 2009 )) years old. UPDATE!!" >&2
				L=1
                                until [ $L -eq $(( TTYUSB_LC + 1 )) ]; do
	                                case "$L" in
        	                                1)
                	                                TTYUSB_ARRAY+=("$($TTYUSB | head -n 1)")
                                                        L=$(( L + 1 ))
                                                        ;;
                                                $TTYUSB_LC)
                                                        TTYUSB_ARRAY+=("$($TTYUSB | tail -n 1)")
                                                        unset L
                                                        ;;
                                                *)
                                                        TTYUSB_ARRAY+=("$($TTYUSB | head -n $L | tail -n 1)")
                                                        L=$(( L + 1 ))
                                                        ;;
                                        esac
                                done

			else
				readarray -t TTYUSB_ARRAY <<< "$($TTYUSB)"
			fi
			echo -e "More than one USB serial devices found.\nEnter desired device name and press [ENTER] (Default=${TTYUSB_ARRAY[0]}).\nPossible input: ${TTYUSB_ARRAY[@]}"
                	readnull SELECTEDTTY
                	while [ 0 -eq 0 ]; do
                        	if [[ ${TTYUSB_ARRAY[@]} =~ "$SELECTEDTTY" ]]; then
                                	echo -e "Attaching to the screen..."
                                	screen -c "$HOME/.screenrc" -R -L $SELECTEDTTY $BAUD_RATE; QMARK=$?
                                	break
                        	elif [ $SELECTEDTTY == "NULL0" ]; then
                                	echo -e "Attaching to the screen..."
                                	screen -c "$HOME/.screenrc" -R -L ${TTYUSB_ARRAY[0]} $BAUD_RATE; QMARK=$?
                        		break
                        	else
                                	echo -e "\nUnknown choice. press [ENTER] to select ${TTYUSB_ARRAY[0]} or enter one of these possible inputs and press [ENTER]: ${TTYUSB_ARRAY[@]}"
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
		echo -e "Backing up current screenrc file..."
		cp -a $HOME/.screenrc $HOME/.screenrc.tmp
	fi
	
	# Checks if the host name is set and modifies the screenrc file.
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
	
	# Checks if the user is in dialout group (Some operating systems and distributions need the user to be in the group).
	DIALOUT=$(cat /etc/group | grep dialout | grep $USER)
	DIALGID=$(cat /etc/group | grep dialout | cut -d ':' -f 3)
	if [ ${#DIALOUT} -eq 0 ]; then
        echo -e "The current user is not found in dialout group (GID $DIALGID).\nThe screen might not work as expected without sudo or adding the user to the group, logging out, and back in.\nPress [ENTER] to continue."
        read RETURN_KEY
	fi
	
	# Checks the operating system and calls the screen.
	case "$(uname)" in
		Linux)
			callscreen "ls /dev/ttyUSB*" || echo -e "Screen terminated with an error. Check the screen log for details."
			;;
		Darwin)
			callscreen "ls /dev/tty.usb*" || echo -e "Screen terminated with an error. Check the screen log for details."
			;;
		FreeBSD)
			callscreen "ls /dev/ttyU* | grep -vE '(init|lock)'" || echo -e " Screen terminated with an error. Check the screen log for details."
			;;
		*)
			echo -e "This script doesn't support this type of operating system yet. Aborting."
			exit 1
			;;
	esac
}

# Prints the script version.
version () {
	echo -e "Breakfast-Serial v0.94.810-7\nA simple bash script for convenient USB Serial Console usage.\nWritten by Sidney Jeong, GNU GPL 3.0"
}

# Prints the usage.
usage () {
	echo -e "Usage: bash usbserial.sh [options]\n\n-b|--baudrate [baudrate] Specifies the baud rate when you connect to the serial port. If this option is not set, it defaults to 115200.\n-h|--hostname [hostname] Specifies the host name you would like to connect to. You can omit this option, but the script will make sure if you really want to leave the hostname blank.\n-v|--version Shows the version of the script.\n--help|--usage Shows this help."
}

restorefile () {
	mv $HOME/.screenrc.tmp $HOME/.screenrc
	if [ $? -eq 0 ]; then
		echo -e "Successfully restored screen user configuration file."
		exit 0
	else
		echo -e "Failed to restore screen user configuration file. Please double-check the file."
		exit 1
	fi
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
			;;
		--help|--usage)
			usage
			exit 0
			;;
		*)
			echo -e "Unknown option -- $1\n"
			usage
			exit 1
			;;
	esac
done

screentty
restorefile
