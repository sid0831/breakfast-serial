#!/usr/bin/env bash
#
# Library for stderr logging.
# Inspired by bitnami's liblog.sh (Apache License).

set -o pipefail

# Constants
RESET='\033[0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'

# Prints message (as argument) to stderr.
print_to_stderr() {
  local bool="${QUIETMODE:-false}"

  shopt -s nocasematch
  if ! [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
    printf "%b\\n" "${*}" >&2
  fi
}

# Prints message in log format.
print_log() {
  print_to_stderr "${CYAN}${MODULE:-} ${MAGENTA}$(date "+%T.%2N ")${RESET}${*}"
}

log_info(){
  print_log "${GREEN}INFO${RESET} ==> ${*}"
}

log_warn(){
  print_log "${YELLOW}WARN${RESET} ==> ${*}"
}

log_error(){
  print_log "${RED}ERROR${RESET} ==> ${*}"
}

log_debug(){
  local bool="${SID_DEBUG:-false}"

  shopt -s nocasematch
  if [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
    print_log "${MAGENTA}DEBUG${RESET} ==> ${*}"
  fi
}
