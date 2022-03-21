#!/bin/sh
set -e

readOsReleaseFile() {
  cat /etc/os-release 2>/dev/null
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

installKsmAlpine() {
  echo "➡️ Install KSM on Alpine"

  apk add --update --no-cache curl

  if [ "${KSM_CLI_VERSION:-latest}" != "latest" ]; then
    VERSION=${KSM_CLI_VERSION}
  else
    # Retrieve latest version
    echo "➡️ Retrieving latest version"
    VERSION=$(curl --silent "https://api.github.com/repos/Keeper-Security/secrets-manager/releases/latest" | grep tag_name | awk -F\" '{ print $4 }' | awk -F- '{print $3}')
  fi

  # Exit if version is already installed
  if command -v ksm >/dev/null 2>&1 && ksm version 2>&1 | grep "CLI Version: " | cut -d " " -f 3 | grep -q "${VERSION}$"; then
    echo "➡️ Version ${VERSION} is already installed"
    exit 0
  fi


  apk add --update --no-cache build-base libffi-dev python3 python3-dev py3-wheel && ln -sf python3 /usr/bin/python;
  python3 -m ensurepip;
  pip3 install --no-cache --upgrade pip setuptools;
  pip3 install keeper-secrets-manager-cli=="${VERSION}"

}

installKsmWithBinary() {
  echo "➡️ Install KSM with binary"

  # Detect OS
  UNAME=$(uname)
  if [ "$UNAME" = "Linux" ]; then
      OS=linux
  else
      echo "❌ Cannot determine compatible OS type. Exiting..."
      exit;
  fi

  # Make sure we have root priviliges.
  SUDO=""
  if [ "$(id -u)" -ne 0 ]; then
      if ! [ "$(command -v sudo)" ]; then
          echo "❌ Installer requires root privileges. Please run this script as root."
          exit;
      fi
      SUDO="sudo"
  fi

  echo "➡️ Creating directories"
  $SUDO mkdir -p /usr/local/ksm/bin

  if [ "${KSM_CLI_VERSION:-latest}" != "latest" ]; then
    VERSION=${KSM_CLI_VERSION}
  else
    # Retrieve latest version
    echo "➡️ Retrieving latest version"
    VERSION=$(curl --silent "https://api.github.com/repos/Keeper-Security/secrets-manager/releases/latest" | grep tag_name | awk -F\" '{ print $4 }' | awk -F- '{print $3}')
  fi

  # Exit if version is already installed
  if command -v ksm >/dev/null 2>&1 && ksm version 2>&1 | grep "CLI Version: " | cut -d " " -f 3 | grep -q "${VERSION}$"; then
    echo "➡️ Version ${VERSION} is already installed"
    exit 0
  fi

  echo "➡️ Downloading version ${VERSION}"
  ARCHIVE_NAME=keeper-secrets-manager-cli-$OS-$VERSION
  LINK_TAR=https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-$VERSION/$ARCHIVE_NAME.tar.gz

  curl -fsSL "${LINK_TAR}" | $SUDO tar -xz -C /usr/local/ksm;

  # symlink in the PATH
  $SUDO ln -sf /usr/local/ksm/ksm /usr/local/bin/ksm
}

InstallKsm() {
  is_alpine=$(isAlpine)

  if [ "$is_alpine" = "true" ]; then
    installKsmAlpine
  else
    installKsmWithBinary
  fi
}

if [ "${0#*$TEST_ENV}" = "$0" ]; then
    InstallKsm
fi
