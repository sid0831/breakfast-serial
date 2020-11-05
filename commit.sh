#!/usr/bin/env bash

VERSINFO=$(grep "VERSION=" $PWD/usbserial.sh | cut -d "\"" -f 2)
VERSARRAY=( $(echo $VERSINFO | cut -d "-" -f 1 | cut -d "." -f 1) $(echo $VERSINFO | cut -d "-" -f 1 | cut -d "." -f 2) $(echo $VERSINFO | cut -d "-" -f 1 | cut -d "." -f 3) $(echo $VERSINFO | cut -d "-" -f 2 | cut -d "." -f 1) $(echo $VERSINFO | cut -d "-" -f 2 | cut -d "." -f 2) )

commitcode () {
  local QMARK=1
  git commit -m "$2" $1; QMARK=$?
  return $QMARK
}

verschange () {
  local QMARK=1
  local COMMITCOUNT=$(git rev-list --count main)
  VERSARRAY[4]=$(( $COMMITCOUNT + 1 ))
  echo -e "Marking new version...\nOLD: v$VERSINFO\nNEW: v${VERSARRAY[0]}.${VERSARRAY[1]}.${VERSARRAY[2]}-${VERSARRAY[3]}.${VERSARRAY[4]}"
  sed -E -i "s/^VERSION=.*$/VERSION=\"${VERSARRAY[0]}.${VERSARRAY[1]}.${VERSARRAY[2]}\-${VERSARRAY[3]}.${VERSARRAY[4]}\"/g" $PWD/usbserial.sh; QMARK=$?
  return $QMARK
}

while [ $# -gt 0 ]; do
  case "$1" in
    -m|--message)
      verschange && commitcode "-a" "$2" && git push && exit 0
      shift; shift
      ;;
    *)
      echo "only -m flag allowed for now"
      exit 1
      ;;
  esac
done
