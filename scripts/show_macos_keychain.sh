#!/bin/sh

set -eu

service="aswitch"
reveal=0
keychain_path=""

usage() {
  cat <<'EOF'
List provider API keys stored by ASwitch in the macOS Keychain.

Usage:
  scripts/show_macos_keychain.sh [--reveal] [--keychain PATH]

Options:
  --reveal    Print the stored API key values in plaintext on stdout.
  --keychain PATH
              Inspect only the specified Keychain.
  -h, --help  Show this help message.

Only generic-password items with service "aswitch" are shown. Environment
variables and API keys stored in aswitch.json are not included.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --reveal)
      reveal=1
      shift
      ;;
    --keychain)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo "error: --keychain requires a path" >&2
        exit 2
      fi
      keychain_path=$2
      shift 2
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
  echo "error: this script can only inspect credentials on macOS" >&2
  exit 1
fi

if ! command -v security >/dev/null 2>&1; then
  echo "error: required command not found: security" >&2
  exit 1
fi

if [ -n "$keychain_path" ]; then
  if ! keychain_dump=$(security dump-keychain "$keychain_path" 2>&1); then
    echo "error: could not list Keychain items in '$keychain_path'" >&2
    exit 1
  fi
else
  if ! keychain_dump=$(security dump-keychain 2>&1); then
    echo "error: could not list macOS Keychain items" >&2
    exit 1
  fi
fi

# dump-keychain without -d shows metadata, never password values.
items=$(printf '%s\n' "$keychain_dump" | awk '
  function show_item() {
    if (item_class == "genp" && item_service == "aswitch" && item_account != "") {
      print item_keychain "\t" item_account
    }
  }
  /^keychain: "/ {
    show_item()
    item_keychain = $0
    sub(/^keychain: "/, "", item_keychain)
    sub(/"$/, "", item_keychain)
    item_class = ""
    item_service = ""
    item_account = ""
  }
  /^class: "genp"$/ { item_class = "genp" }
  /^[[:space:]]*"acct"<blob>="/ {
    item_account = $0
    sub(/^[[:space:]]*"acct"<blob>="/, "", item_account)
    sub(/"$/, "", item_account)
  }
  /^[[:space:]]*"svce"<blob>="/ {
    item_service = $0
    sub(/^[[:space:]]*"svce"<blob>="/, "", item_service)
    sub(/"$/, "", item_service)
  }
  END { show_item() }
')

if [ -z "$items" ]; then
  echo "No ASwitch API keys were found in the macOS Keychain."
  exit 0
fi

while IFS="$(printf '\t')" read -r item_keychain item_account; do
  if [ "$reveal" -eq 1 ]; then
    if item_value=$(security find-generic-password \
        -s "$service" -a "$item_account" -w "$item_keychain" 2>/dev/null); then
      printf '%s: %s\n' "$item_account" "$item_value"
    else
      printf '%s: <could not read key>\n' "$item_account" >&2
      exit 1
    fi
  else
    printf '%s\n' "$item_account"
  fi
done <<EOF
$items
EOF
