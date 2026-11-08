#!/bin/sh
set -e

InstallKsm() {
  is_alpine=$(isAlpine)
  if [ "$is_alpine" = "true" ]; then
    prepareEnvOnAlpine
  elif isAzureLinux; then
    prepareEnvOnAzureLinux
  fi

  if [ "${KSM_INSTALL_DIR}" = "" ]; then
    INSTALL_PATH=/tmp/keeper
  else
    INSTALL_PATH=${KSM_INSTALL_DIR}
  fi


  if [ "${KSM_CLI_VERSION:-latest}" != "latest" ]; then
    VERSION=${KSM_CLI_VERSION}
  else
    VERSION=$(getLatestVersion)
  fi

  # Exit if version is already installed
  if isVersionAlreadyInstalled; then
    echo "➡️ Version ${VERSION} is already installed"
    exit 0
  fi

  LINK_TAR="$(buildBinaryUrl "$VERSION" "$is_alpine")"

  installKsmWithBinary "$LINK_TAR" "$INSTALL_PATH"
}

isAlpine() {
  os_release_id=$(readOsReleaseFile | grep ^ID= | cut -d "=" -f 2)
  if [ "$os_release_id" = "alpine" ];
  then
    echo "true"
  else
    echo "false"
  fi
}

isAzureLinux() {
  grep '^ID=' /etc/*release* | grep -q -i azurelinux
}

readOsReleaseFile() {
  cat /etc/os-release 2>/dev/null
}

isLinux() {
  UNAME=$(uname)
  if [ "$UNAME" = "Linux" ]; then
    echo "true"
  else
    echo "false"
  fi
}

getLatestVersion() {
  curl --silent "https://api.github.com/repos/Keeper-Security/secrets-manager/releases" | sed -n '/tag_name/{/ksm-cli/{s/^.*ksm-cli-\([0-9.]*\)",$/\1/p}}' | sort -V | tail -n 1
}

isVersionAlreadyInstalled() {
  command -v ksm >/dev/null 2>&1 && ksm version 2>&1 | grep "CLI Version: " | cut -d " " -f 3 | grep -q "${VERSION}$"
}

buildBinaryUrl() {
  VERSION=$1
  is_alpine=$2

  if [ "$is_alpine" = "true" ]; then
      OS=alpine-linux
  else
    is_linux=$(isLinux)
    if [ "$is_linux" = "true" ]; then
        OS=linux
    else
        echo "❌ Cannot determine compatible OS type. Exiting..."
        exit 1;
    fi
  fi

  ARCHIVE_NAME=keeper-secrets-manager-cli-$OS-$VERSION
  echo "https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-$VERSION/$ARCHIVE_NAME.tar.gz"
}

fetchBinary() {
  LINK_TAR=$1
  TARGET=$2

  mkdir -p "${TARGET}"
  ARCHIVE=$(mktemp)
  if ! download "${LINK_TAR}" "${ARCHIVE}"; then
    rm -f "${ARCHIVE}"
    echo "❌ Cannot download ${LINK_TAR}. Exiting..."
    exit 1
  fi
  tar -xzf "${ARCHIVE}" -C "${TARGET}"
  rm -f "${ARCHIVE}"

  # Update in the PATH
  echo "export PATH=${PATH}:${TARGET}" >> "$BASH_ENV"
}

# Downloads <url> into <file>. A failing or stalled download (5xx such as GitHub's 504, network error, less than
# 1 kB/s for 20 s) is tried again, up to KSM_DOWNLOAD_ATTEMPTS times, waiting a little longer each time. A client
# error such as a 404 for a version that does not exist fails at once: another attempt would get the same answer.
download() {
  attempt=1
  max_attempts=${KSM_DOWNLOAD_ATTEMPTS:-5}
  while :; do
    status=$(curl --fail --silent --show-error --location --connect-timeout 20 --speed-limit 1024 --speed-time 20 \
      --write-out '%{http_code}' --output "$2" "$1") && return 0
    case $status in 408 | 429) ;; 4??) return 1 ;; esac
    [ "$attempt" -lt "$max_attempts" ] || return 1
    delay=$((attempt * ${KSM_DOWNLOAD_RETRY_DELAY:-5}))
    echo "⚠️ Download of $1 failed (HTTP ${status:-none}), retrying in ${delay}s (${attempt}/${max_attempts})"
    sleep "$delay"
    attempt=$((attempt + 1))
  done
}

installKsmWithBinary() {
  LINK_TAR=$1
  INSTALL_PATH=$2
  echo "➡️ Install KSM from ${LINK_TAR}"

  fetchBinary "$LINK_TAR" "$INSTALL_PATH"
}

prepareEnvOnAlpine() {
  apk add --update --no-cache curl
}

prepareEnvOnAzureLinux() {
  tdnf install -y tar awk curl
}

if [ "${0#*"$TEST_ENV"}" = "$0" ]; then
    InstallKsm
fi
