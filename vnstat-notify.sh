#!/bin/sh

ENV_FILE="/etc/vnstat-notify.env"

if [ ! -r "${ENV_FILE}" ]; then
  echo "Error: ${ENV_FILE} not found or not readable" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "${ENV_FILE}"

if [ -z "${APPRISE_URLS}" ]; then
  echo "Error: APPRISE_URLS is not set" >&2
  exit 1
fi

if [ -z "${NOTIFY_VNSTAT_ARGS}" ]; then
  echo "Error: NOTIFY_VNSTAT_ARGS is not set" >&2
  exit 1
fi

title="${NOTIFY_TITLE:-vnStat}"
if [ -n "${SERVER_NAME}" ]; then
  title="${SERVER_NAME}: ${title}"
fi

# shellcheck disable=SC2086
set -- ${NOTIFY_VNSTAT_ARGS}

body_file=$(mktemp)
err_file=$(mktemp)

trap 'rm -f "${body_file}" "${err_file}"' EXIT INT TERM

if ! vnstat "$@" >"${body_file}" 2>"${err_file}"; then
  echo "Error: vnstat command failed" >&2
  cat "${err_file}" >&2
  exit 1
fi

if [ -s "${err_file}" ]; then
  cat "${err_file}" >&2
fi

if ! grep -q '[^[:space:]]' "${body_file}"; then
  echo "vnstat command produced no output, notification skipped" >&2
  exit 0
fi

if ! apprise -t "${title}" -b "$(cat "${body_file}")"; then
  echo "Error: apprise command failed to send notification" >&2
  exit 1
fi

echo "notification sent"
