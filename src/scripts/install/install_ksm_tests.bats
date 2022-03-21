#!/usr/bin/env bats

setup() {
  export TEST_ENV="bats-core"

  source ./src/scripts/install/install_ksm.sh

  installKsmAlpine() {
    echo "installKsmAlpine"
  }

  installKsmWithBinary() {
    echo "installKsmWithBinary"
  }
}

teardown() {
    rm -f /tmp/bashenv
    rm -f /tmp/keeper.ini
}

@test "InstallKsm should install KSM for Alpine when running on Alpine Linux" {
  readOsReleaseFile() {
    echo "ID=alpine"
  }

  result=$(InstallKsm)
  [ "$result" == "installKsmAlpine" ]
}

@test "InstallKsm should install KSM with binary when not running on Alpine Linux" {
  readOsReleaseFile() {
    echo "ID=other"
  }

  result=$(InstallKsm)
  [ "$result" == "installKsmWithBinary" ]
}

@test "InstallKsm should install KSM with binary when /etc/os-release file does not exist" {
  readOsReleaseFile() {
    echo ""
  }

  result=$(InstallKsm)
  [ "$result" == "installKsmWithBinary" ]
}
