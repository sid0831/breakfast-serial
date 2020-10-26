#!/usr/bin/env bash

VERSINFO=( $(cat $PWD/bserial.ver) )

commitcode () {
  local QMARK=1
  git commmit -m "$2" $1; QMARK=$?
  return $QMARK
}

verschange () {
  local QMARK=1
  ${VERSINFO[5]}=$(( ${VERSINFO[5]} + 1 ))
  echo "${VERSINFO[@]}" > $PWD/bserial.ver; QMARK=$?
  return $QMARK
}

while [ $# -gt 0 ]; do
  case "$1" in
    -m|--message)
      shift
      verschange && commitcode "-a" "$1" && git push && exit 0
      ;;
    *)
      echo "only -m flag allowed for now"
      exit 1
      ;;
  esac
done
