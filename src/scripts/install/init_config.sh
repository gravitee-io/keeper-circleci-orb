#!/bin/bash
set -o errexit  # Exit when simple command fails               'set -e'
set -o errtrace # Exit on error inside any functions or subshells.
set -o pipefail # Do not hide errors within pipes              'set -o pipefail'

ksm_init_config(){
  ksm version
}

InitKeeperConfig() {
  if [ "x${KEEPER_INI_DIR}" == "x" ]; then
    >&2 echo "KEEPER_INI_DIR env var not set"
    exit 1
  fi

  echo "KSM_INI_DIR=${KEEPER_INI_DIR}" >> "$BASH_ENV"

  cd /tmp
  ksm_init_config
}

# Will not run if sourced from another script.
# This is done so this script may be tested.
if [ "${0#*$TEST_ENV}" == "$0" ]; then
    InitKeeperConfig
fi
