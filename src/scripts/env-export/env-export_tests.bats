#!/usr/bin/env bats

setup() {
  export TEST_ENV="bats-core"
  export BASH_ENV=/tmp/bashenv
  export INSTALL_DIR=/tmp/keeper
  export SECRET_ENV_NAME=MY_ENV
  export SECRET_URL=my_secret_url

  source ./src/scripts/env-export/env-export.sh

  # Overrides get_secret_from_ksm function
  get_secret_from_ksm() {
    touch keeper.ini
    echo "$1"
  }
}

teardown() {
    rm -f /tmp/bashenv
    rm -f /tmp/keeper.ini
}

@test "EnvExport should add export command to set the secret in an env variable" {
  run EnvExport
  [ "$status" -eq 0 ]

  source /tmp/bashenv
  if [[ "$MY_ENV" != "$SECRET_URL" ]]; then
    echo
    echo "MY_ENV env invalid"
    echo "Expected MY_ENV=${SECRET_URL}, but was MY_ENV=${MY_ENV}"
    echo "Content of export command: $(cat /tmp/bashenv)"
    exit 1;
  fi
}

@test "EnvExport should initialize keeper.ini file in /tmp" {
  run EnvExport
  [ "$status" -eq 0 ]

  if [[ ! -f "/tmp/keeper.ini" ]]; then
    echo "/tmp/keeper.ini does not exist."
    exit 1;
  fi
}

@test "EnvExport should not change the current directory" {
  pwd_before=$(pwd)

  run EnvExport
  [ "$status" -eq 0 ]

  pwd_after=$(pwd)

  if [[ "$pwd_before" != "$pwd_after" ]]; then
    echo "Current directory has changed."
    exit 1;
  fi
}

@test "EnvExport should fail when SECRET_ENV_NAME not set" {
  unset SECRET_ENV_NAME

  run EnvExport
  [ "$status" -eq 1 ]
  [ "$output" = "SECRET_ENV_NAME env var not set" ]
}

@test "EnvExport should fail when SECRET_URL not set" {
  unset SECRET_URL

  run EnvExport
  [ "$status" -eq 1 ]
  [ "$output" = "SECRET_URL env var not set" ]
}
