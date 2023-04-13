#!/usr/bin/env bash
#
# USB serial port attachment script using GNU Screen.
# Written by Sidney Jeong, MPL 2.0.

set -o pipefail

# Constants
VERSION="1.13.0"
MODULE="$(basename $0)"
APPROOT="${PWD}"

# Variables
declare -gi BAUD_RATE=115200
declare -g HOST_NAME="$(hostname -s)"
declare -g TGT_TTY=""
export SID_DEBUG="false"
case "$(uname)" in
  Linux) TGT_TTY="$(ls /dev/ttyUSB* 2>/dev/null | head -n 1 )" ;;
  Darwin) TGT_TTY="$(ls /dev/tty.usb* 2>/dev/null | grep -v 'blue' | head -n 1 )" ;;
  FreeBSD) TGT_TTY="$(ls /dev/ttyU* 2>/dev/null | grep -vE '(init|lock)' | head -n 1 )" ;;
  *) log_error "This script doesn't support this type of operating system yet. Aborting." && exit 1 ;;
esac

# Sourcing libraries.
[[ -e "${APPROOT}/lib" ]] && . ${APPROOT}/lib/liblog.sh || . ${APPROOT}/../lib/liblog.sh

_help() {
  _version
  echo -ne '\n'
  cat << EOF
Usage: ./usbserial.sh [options]
  -b|--baudrate [baudrate] Specifies the baud rate when you connect to the serial port. If this option is not set, it defaults to 115200.
  -n|--hostname [hostname] Specifies the host name you would like to connect to. You can omit this option, but the script will make sure if you really want to leave the hostname blank.
  -t|--tty [target TTY] Specifies the target tty in full path. It defaults to first USB Serial device (/dev/ttyUSB0 in Linux).
  -v|--version Shows the version of the script.
  -h|--help|--usage Shows this help.
EOF
}

_version() {
  cat << EOF
Breakfast-Serial v${VERSION}
A simple bash script for convenient USB Serial attachments.
Written by Sidney Jeong, MPL 2.0
EOF
}

# Checks if the user is in dialout/dialer/uucp group (Some operating systems and distributions need the user to be in the group).
_check_group() {
  local DIALOUT=$(grep -E '(dialout|dialer|uucp)' /etc/group | grep $USER | head -n 1)
  local DIALGNAME=$(grep -E '(dialout|dialer|uucp)' /etc/group | cut -d ':' -f 1 | head -n 1)
  local DIALGID=$(grep -E '(dialout|dialer|uucp)' /etc/group | cut -d ':' -f 3 | head -n 1)
  if [ ${#DIALOUT} -eq 0 ]; then
    log_warn "The current user is not found in ${DIALGNAME} group (GID ${DIALGID}).\nThe screen might not work as expected without sudo or adding the user to the group, logging out, and back in.\nPress [ENTER] to continue."
    read -r RETURN_KEY
  else
    log_debug "The user is in the group ${DIALGNAME}"
  fi
}

# Modifies the screenrc file.
_replace_screenrc() {
  # Checks if the log directory exists and if it doesn't, creates it.
  if [ -d $HOME/screen_log ]; then
    log_debug "The log directory exists. Continuing..."
  else
    log_info "Creating the log directory..."
    mkdir -p $HOME/screen_log
  fi
  # Backs up current screenrc file
  if [ -f $HOME/.screenrc ]; then
    log_info "Backing up current screenrc file...\n"
    cp -a $HOME/.screenrc $HOME/.screenrc.tmp
  fi
  cat << EOF > $HOME/.screenrc
logfile "$HOME/screen_log/`date +%Y-%m-%dT%H%M%S%z`-$USER-`echo $HOST_NAME`-serialconsole-diagnose.log"
logfile flush 1
termcapinfo xterm*|rxvt*|kterm*|Eterm* ti@:te@
termcapinfo rxvt* 'hs:ts=\E]2;:fs=\007:ds=\E]2;\007'
backtick 1 5 5 true
shelltitle "\$ |PLAC3H0LDER:"
hardstatus off
caption string "%{= kw}%Y-%m-%d;%c %{= kw}%-Lw%{= kG}%{+b}[%n %t]%{-b}%{= kw}%+Lw"
caption always
logstamp off
log on
EOF
}

_call_screen() {
  log_info "Attaching to the USB serial port..."
  sed -i "s/PLAC3H0LDER/$(basename ${TGT_TTY})/g" ${HOME}/.screenrc
  screen -c "${HOME}/.screenrc" -R -L ${TGT_TTY} ${BAUD_RATE}
  return $?
}

#simple flag parsing.
[[ $# -eq 0 ]] && log_error "At least one argument needed.\n" && _help && exit 126

_parse_flags () {
  while [[ ${#} -gt 0 ]]; do
  case "${1}" in
    -b|--baudrate*)
      if [[ "$1" =~ "=" && "${1#--baudrate=}" -ge 72 && "${1#--baudrate=}" -le 256000 ]]; then
        BAUD_RATE=${1#--baudrate=}
      elif [[ "$2" -ge 72 && "$2" -le 256000 ]]; then
        shift; BAUD_RATE=${1}
      else
        log_error "Wrong baud rate specified. Check your input and retry."
        exit 1
      fi
      ;;
    -n|--hostname*)
      if [[ "$1" =~ "=" ]]; then
        HOST_NAME=${1#--hostname=}
      else
        shift; HOST_NAME=${1}
      fi
      ;;
    -t|--tty*)
      if [[ "$1" =~ "=" ]]; then
        TGT_TTY=${1#--tty=}
      else
        shift; TGT_TTY=${1}
      fi
      ;;
    -d|--debug)
      export SID_DEBUG="true"
      ;;
    -v|--version) _version && exit 0 ;;
    -h|--help|--usage) _help && exit 0 ;;
    *) log_info "\"$1\" is ignored." ;;
  esac
  shift
  done
}

_parse_flags "$@"

log_debug "Baudrate: ${BAUD_RATE} Hostname: ${HOST_NAME} TTY: ${TGT_TTY}"

if [[ -n "${TGT_TTY}" ]]; then
  log_debug "Yay. found a TTY"
  _check_group
  _replace_screenrc
  _call_screen
  cp -a ${HOME}/.screenrc.tmp ${HOME}/.screenrc && log_info "Successfully restored the screenrc file." || log_warn "Screenrc file was not successfully restored. Check the file."
else
  log_error "Cannot find a TTY to attach. Aborting."
  exit 2
fi