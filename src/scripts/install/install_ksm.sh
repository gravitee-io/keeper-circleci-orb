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
  curl -fsSL "${LINK_TAR}" | tar -xz -C "${TARGET}";

  # Update in the PATH
  echo "export PATH=${PATH}:${TARGET}" >> "$BASH_ENV"
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
