#!/usr/bin/env bash

VERSINFO=$(cat $PWD/usbserial.sh | grep -iE 'Breakfast-Serial v' | sed -E 's/([ \t].*)(echo -e "Breakfast-Serial v)(.*)(\\nA.*)/\3/g')
VERSARRAY=( $(echo "$VERSINFO" | sed -E 's/([0-9]{1})(\.)([0-9]{2})(\.)([0-9]{3})(\-)([0-9]{1})(\.)([0-9]{2})/\1/') $(echo "$VERSINFO" | sed -E 's/([0-9]{1})(\.)([0-9]{2})(\.)([0-9]{3})(\-)([0-9]{1})(\.)([0-9]{2})/\3/') $(echo "$VERSINFO" | sed -E 's/([0-9]{1})(\.)([0-9]{2})(\.)([0-9]{3})(\-)([0-9]{1})(\.)([0-9]{2})/\5/') $(echo "$VERSINFO" | sed -E 's/([0-9]{1})(\.)([0-9]{2})(\.)([0-9]{3})(\-)([0-9]{1})(\.)([0-9]{2})/\7/') $(echo "$VERSINFO" | sed -E 's/([0-9]{1})(\.)([0-9]{2})(\.)([0-9]{3})(\-)([0-9]{1})(\.)([0-9]{2})/\9/') )
COMMITCOUNT=$(git rev-list --count main)

commitcode () {
  local QMARK=1
  git commit -m "$2" $1; QMARK=$?
  return $QMARK
}

verschange () {
  local QMARK=1
  ${VERSARRAY[4]}=$(( $COMMITCOUNT + 1 ))
  echo -e "Marking new version...\nOLD: v$VERSINFO\nNEW: v${VERSARRAY[0]}.${VERSARRAY[1]}.${VERSARRAY[2]}-${VERSARRAY[3]}.${VERSARRAY[4]}"
  sed -E -i "s/([0-9]{1})(\.)([0-9]{2})(\.)([0-9]{3})(\-)([0-9]{1})(\.)([0-9]{2})/${VERSARRAY[0]}.${VERSARRAY[1]}.${VERSARRAY[2]}\-${VERSARRY[3]}.${VERSARRAY[4]}/g" $PWD/usbserial.sh; QMARK=$?
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
