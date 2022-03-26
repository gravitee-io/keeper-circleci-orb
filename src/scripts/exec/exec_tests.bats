#!/usr/bin/env bats

setup() {
  export TEST_ENV="bats-core"
  export BASH_ENV=/tmp/bashenv
  export SHELL=/bin/sh
  export COMMAND="echo \"secret: \$MY_USER\""

  source ./src/scripts/exec/exec.sh

  KsmExec() {
    return 0
  }
}

teardown() {
    rm -f /tmp/ksm_exec.sh
}

@test "Exec should create a temporary file containing the command to execute" {
  run Exec
  [ "$status" -eq 0 ]

  if [[ ! -f "/tmp/ksm_exec.sh" ]]; then
    echo "/tmp/ksm_exec.sh does not exist."
    exit 1;
  fi

  expected=$(
    cat << EOF
#!/bin/sh
echo "secret: \$MY_USER"
EOF
)
  result=$(cat /tmp/ksm_exec.sh)

  [ "$result" == "$expected" ]
}

@test "Exec should fail when COMMAND not set" {
  unset COMMAND

  run Exec
  [ "$status" -eq 1 ]
  [ "$output" = "COMMAND env var not set. Nothing to execute" ]
}
