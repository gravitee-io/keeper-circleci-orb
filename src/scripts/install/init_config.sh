#!/bin/sh
set -e

ksm_init_config(){
  ksm version
}

InitKeeperConfig() {
  if [ "${KEEPER_INI_DIR}" = "" ]; then
    >&2 echo "KEEPER_INI_DIR env var not set"
    exit 1
  fi

  echo "KSM_INI_DIR=${KEEPER_INI_DIR}" >> "$BASH_ENV"

  cd /tmp
  ksm_init_config
}

# Will not run if sourced from another script.
# This is done so this script may be tested.
if [ "${0#*"$TEST_ENV"}" = "$0" ]; then
    InitKeeperConfig
fi
