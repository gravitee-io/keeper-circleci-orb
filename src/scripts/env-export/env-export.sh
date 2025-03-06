#!/bin/sh
set -e

generate_random_heredoc_identifier() {
  < /dev/urandom env LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
}

get_secret_from_ksm() {
  url=$1
  "${KSM_INSTALL_DIR}/ksm" secret notation "${url}"
}

EnvExport() {
  if [ "${SECRET_ENV_NAME}" = "" ]; then
    >&2 echo "SECRET_ENV_NAME env var not set"
    exit 1
  fi

  if [ "${SECRET_URL}" = "" ]; then
    >&2 echo "SECRET_URL env var not set"
    exit 1
  fi

  cd /tmp

  # To support multiline secrets, we'll use the heredoc syntax to populate the environment variables.
  # As the heredoc identifier, we'll use a randomly generated 64-character string,
  # so that collisions are practically impossible.
  random_heredoc_identifier=$(generate_random_heredoc_identifier) || true
  SECRET=$(get_secret_from_ksm "${SECRET_URL}")

  {
    printf "export %s=\$(cat <<%s\n" "${SECRET_ENV_NAME}" "${random_heredoc_identifier}"
    printf "%s\n" "${SECRET}"
    printf "%s\n)\n" "${random_heredoc_identifier}"
  } >> "${BASH_ENV}"
}

# Will not run if sourced from another script.
# This is done so this script may be tested.
if [ "${0#*"$TEST_ENV"}" = "$0" ]; then
    EnvExport
fi
