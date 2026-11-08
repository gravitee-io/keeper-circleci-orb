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

@test "download should retry on a server error and succeed" {
  sleep() { :; }
  curl() {
    count=$(($(cat /tmp/ksm_curl_calls 2>/dev/null || echo 0) + 1))
    echo "$count" > /tmp/ksm_curl_calls
    if [ "$count" -lt 3 ]; then printf 504; return 22; fi
    printf 200
  }
  rm -f /tmp/ksm_curl_calls

  run download "https://example.com/ksm.tar.gz" /tmp/ksm.tar.gz

  [ "$status" -eq 0 ]
  [ "$(cat /tmp/ksm_curl_calls)" -eq 3 ]
  rm -f /tmp/ksm_curl_calls
}

@test "download should give up after the maximum number of attempts" {
  sleep() { :; }
  curl() {
    count=$(($(cat /tmp/ksm_curl_calls 2>/dev/null || echo 0) + 1))
    echo "$count" > /tmp/ksm_curl_calls
    printf 504; return 22
  }
  rm -f /tmp/ksm_curl_calls

  KSM_DOWNLOAD_ATTEMPTS=4 run download "https://example.com/ksm.tar.gz" /tmp/ksm.tar.gz

  [ "$status" -eq 1 ]
  [ "$(cat /tmp/ksm_curl_calls)" -eq 4 ]
  rm -f /tmp/ksm_curl_calls
}

@test "download should not retry on a client error" {
  sleep() { :; }
  curl() {
    count=$(($(cat /tmp/ksm_curl_calls 2>/dev/null || echo 0) + 1))
    echo "$count" > /tmp/ksm_curl_calls
    printf 404; return 22
  }
  rm -f /tmp/ksm_curl_calls

  run download "https://example.com/ksm.tar.gz" /tmp/ksm.tar.gz

  [ "$status" -eq 1 ]
  [ "$(cat /tmp/ksm_curl_calls)" -eq 1 ]
  rm -f /tmp/ksm_curl_calls
}
