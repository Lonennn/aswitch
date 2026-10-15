#!/bin/sh

set -eu

keychain_service="aswitch"
assume_yes=0

usage() {
  cat <<'EOF'
Remove all ASwitch provider credentials from the macOS Keychain.

Usage:
  scripts/clear_macos_keychain.sh [--yes]

Options:
  --yes       Skip the confirmation prompt.
  -h, --help  Show this help message.

This removes generic-password items whose service is exactly "aswitch". It
does not modify aswitch.json or remove the ASwitch code-signing identity.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --yes)
      assume_yes=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: this script can only clear credentials on macOS" >&2
  exit 1
fi

if ! command -v security >/dev/null 2>&1; then
  echo "error: required command not found: security" >&2
  exit 1
fi

if [ "$assume_yes" -ne 1 ]; then
  if [ ! -t 0 ]; then
    echo "error: confirmation requires an interactive terminal; pass --yes to continue" >&2
    exit 2
  fi
  printf 'Remove all ASwitch provider credentials from the macOS Keychain? [y/N] '
  IFS= read -r answer
  case "$answer" in
    y|Y|yes|YES|Yes)
      ;;
    *)
      echo "Canceled."
      exit 0
      ;;
  esac
fi

deleted=0
while :; do
  if delete_output=$(security delete-generic-password \
      -s "$keychain_service" 2>&1); then
    deleted=1
    continue
  else
    delete_status=$?
  fi
  if [ "$delete_status" -eq 44 ]; then
    break
  fi
  echo "error: failed to remove ASwitch credentials from the macOS Keychain" >&2
  if [ -n "$delete_output" ]; then
    printf '%s\n' "$delete_output" >&2
  fi
  exit 1
done

if [ "$deleted" -eq 1 ]; then
  echo "Removed all ASwitch provider credentials from the macOS Keychain."
else
  echo "No ASwitch provider credentials were found in the macOS Keychain."
fi
