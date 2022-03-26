#!/bin/bash
set -e

Exec() {
   if [ -z "${COMMAND:-}" ]; then
     >&2 echo "COMMAND env var not set. Nothing to execute"
     exit 1
   fi

   cat <<EOF > /tmp/ksm_exec.sh
#!$SHELL
$COMMAND
EOF

  chmod 755 /tmp/ksm_exec.sh

  KsmExec
}

KsmExec() {
  ksm exec -- /tmp/ksm_exec.sh
}


# Will not run if sourced from another script.
# This is done so this script may be tested.
if [ "${0#*$TEST_ENV}" = "$0" ]; then
    Exec
fi
