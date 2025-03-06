#!/usr/bin/env bats

setup() {
  export TEST_ENV="bats-core"

  source ./src/scripts/install/install_ksm.sh

  prepareEnvOnAlpine() {
    echo "prepareEnvOnAlpine"
  }

  isLinux() {
    echo "true"
  }

  getLatestVersion() {
    echo "1.0.8"
  }

  isVersionAlreadyInstalled() {
    return 1
  }

  fetchBinary() {
    echo "fetch $1"
  }
}

teardown() {
    rm -f /tmp/bashenv
    rm -f /tmp/keeper.ini
}

@test "InstallKsm should install KSM when running on Alpine Linux" {
  readOsReleaseFile() {
    echo "ID=alpine"
  }

  expected=$(
  cat << EOF
prepareEnvOnAlpine
➡️ Install KSM from https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-1.0.8/keeper-secrets-manager-cli-alpine-linux-1.0.8.tar.gz
fetch https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-1.0.8/keeper-secrets-manager-cli-alpine-linux-1.0.8.tar.gz
EOF
  )

  result=$(InstallKsm)

  [ "$result" == "$expected" ]
}

@test "InstallKsm should install KSM when not running on Alpine Linux" {
  readOsReleaseFile() {
    echo "ID=other"
  }

  expected=$(
  cat << EOF
➡️ Install KSM from https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-1.0.8/keeper-secrets-manager-cli-linux-1.0.8.tar.gz
fetch https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-1.0.8/keeper-secrets-manager-cli-linux-1.0.8.tar.gz
EOF
  )

  result=$(InstallKsm)
  [ "$result" == "$expected" ]
}

@test "InstallKsm should install KSM with binary when /etc/os-release file does not exist" {
  readOsReleaseFile() {
    echo ""
  }

  expected=$(
  cat << EOF
➡️ Install KSM from https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-1.0.8/keeper-secrets-manager-cli-linux-1.0.8.tar.gz
fetch https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-1.0.8/keeper-secrets-manager-cli-linux-1.0.8.tar.gz
EOF
  )

  result=$(InstallKsm)
  [ "$result" == "$expected" ]
}

@test "InstallKsm should not install KSM version already installed" {
  isVersionAlreadyInstalled() {
    return 0
  }

  result=$(InstallKsm)
  [ "$result" == "➡️ Version 1.0.8 is already installed" ]
}
