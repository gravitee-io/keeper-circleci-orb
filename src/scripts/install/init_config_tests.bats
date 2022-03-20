#!/usr/bin/env bats

setup() {
  export TEST_ENV="bats-core"
  export BASH_ENV=/tmp/bashenv
  export KEEPER_INI_DIR=/tmp

  source ./src/scripts/install/init_config.sh

  ksm_init_config(){
    touch $KEEPER_INI_DIR/keeper.ini
  }
}

teardown() {
    rm -f /tmp/bashenv
    rm -f /tmp/keeper.ini
}

@test "InitKeeperConfig should add export command to set KSM_INI_DIR in an env variable" {
  run InitKeeperConfig
  [ "$status" -eq 0 ]

  source /tmp/bashenv
  if [[ "$KSM_INI_DIR" != "$KEEPER_INI_DIR" ]]; then
    echo
    echo "KSM_INI_DIR env invalid"
    echo "Expected KSM_INI_DIR=${KEEPER_INI_DIR}, but was KSM_INI_DIR=${KSM_INI_DIR}"
    echo "Content of export command: $(cat /tmp/bashenv)"
    exit 1;
  fi
}

@test "InitKeeperConfig should initialize keeper.ini file" {
  run InitKeeperConfig
  [ "$status" -eq 0 ]

  if [[ ! -f "/tmp/keeper.ini" ]]; then
    echo "/tmp/keeper.ini does not exist."
    exit 1;
  fi
}

@test "InitKeeperConfig should fail when KEEPER_INI_DIR not set" {
  unset KEEPER_INI_DIR

  run InitKeeperConfig
  [ "$status" -eq 1 ]
  [ "$output" = "KEEPER_INI_DIR env var not set" ]
}
