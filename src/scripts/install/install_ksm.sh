#!/bin/sh
set -e

# Colors
NO_COLOR="\033[0m"
OK_COLOR="\033[32;01m"
ERROR_COLOR="\033[31;01m"

# Detect OS
UNAME=$(uname)
if [ "$UNAME" = "Linux" ]; then
    OS=linux
else
    echo "${ERROR_COLOR}Cannot determine compatible OS type. Exiting...${NO_COLOR}"
    exit;
fi

# Make sure we have root priviliges.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if ! [ "$(command -v sudo)" ]; then
        echo "${ERROR_COLOR}Installer requires root privileges. Please run this script as root.${NO_COLOR}"
        exit;
    fi
    SUDO="sudo"
fi

echo "${OK_COLOR}==> Creating directories${NO_COLOR}"
$SUDO mkdir -p /usr/local/ksm/bin

if [ "${KSM_CLI_VERSION:-latest}" != "latest" ]; then
  VERSION=${KSM_CLI_VERSION}
else
  # Retrieve latest version
  echo "${OK_COLOR}==> Retrieving latest version${NO_COLOR}"
  VERSION=$(curl --silent "https://api.github.com/repos/Keeper-Security/secrets-manager/releases/latest" | grep tag_name | awk -F\" '{ print $4 }' | awk -F- '{print $3}')
fi

# Exit if version is already installed
if command -v ksm >/dev/null 2>&1 && ksm version 2>&1 | grep "CLI Version: " | cut -d " " -f 3 | grep -q "${VERSION}$"; then
  echo "${OK_COLOR}==> Version ${VERSION} is already installed${NO_COLOR}"
  exit 0
fi

echo "${OK_COLOR}==> Downloading version ${VERSION}${NO_COLOR}"
ARCHIVE_NAME=keeper-secrets-manager-cli-$OS-$VERSION
LINK_TAR=https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-$VERSION/$ARCHIVE_NAME.tar.gz

curl -fsSL "${LINK_TAR}" | $SUDO tar -xz -C /usr/local/ksm;

# symlink in the PATH
$SUDO ln -sf /usr/local/ksm/ksm /usr/local/bin/ksm
