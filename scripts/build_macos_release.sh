#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Build and sign the ASwitch macOS release executable.

Usage:
  scripts/build_macos_release.sh [OPTIONS]

Options:
  --identity ID    Code-signing identity. Defaults to "ASwitch Local Signing".
  --identifier ID  Stable identifier. Defaults to "dev.lonen44.aswitch".
  --mode MODE      Signing mode: "local" (default) or "distribution".
  -h, --help       Show this help message.

Examples:
  scripts/build_macos_release.sh
  scripts/build_macos_release.sh \
    --identity "Developer ID Application: Example Corp (TEAMID)" \
    --mode distribution
EOF
}

signing_identity="ASwitch Local Signing"
signing_identifier="dev.lonen44.aswitch"
signing_mode="local"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --identity)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo "error: --identity requires a value" >&2
        exit 2
      fi
      signing_identity=$2
      shift 2
      ;;
    --identifier)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo "error: --identifier requires a value" >&2
        exit 2
      fi
      signing_identifier=$2
      shift 2
      ;;
    --mode)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo "error: --mode requires a value" >&2
        exit 2
      fi
      signing_mode=$2
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
  echo "error: this script can only build a macOS release" >&2
  exit 1
fi

for command_name in moon codesign; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "error: required command not found: $command_name" >&2
    exit 1
  fi
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
binary="$project_root/_build/native/release/build/cmd/aswitch/aswitch.exe"

case "$signing_mode" in
  local|distribution)
    ;;
  *)
    echo "error: --mode must be 'local' or 'distribution'" >&2
    exit 2
    ;;
esac

echo "Building ASwitch release for macOS..."
(
  cd "$project_root"
  moon build src/cmd/aswitch --target native --release
)

if [ ! -f "$binary" ]; then
  echo "error: release executable was not created at $binary" >&2
  exit 1
fi

echo "Signing with identity: $signing_identity"
echo "Signing identifier: $signing_identifier"

if [ "$signing_mode" = "distribution" ]; then
  codesign \
    --force \
    --sign "$signing_identity" \
    --identifier "$signing_identifier" \
    --options runtime \
    --timestamp \
    "$binary"
else
  codesign \
    --force \
    --sign "$signing_identity" \
    --identifier "$signing_identifier" \
    --timestamp=none \
    "$binary"
fi

codesign --verify --strict --verbose=2 "$binary"

echo "Signed release: $binary"
