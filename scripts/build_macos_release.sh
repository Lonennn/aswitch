#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Build and sign the ASwitch macOS release executable.

Usage:
  scripts/build_macos_release.sh --identity ID [OPTIONS]

Options:
  --identity ID    Apple-issued code-signing identity. Required.
  --identifier ID  Stable identifier. Defaults to "dev.lonen44.aswitch".
  --mode MODE      Signing mode: "local" (default) or "distribution".
  -h, --help       Show this help message.

Examples:
  scripts/build_macos_release.sh \
    --identity "Apple Development: Example Developer (TEAMID)"
  scripts/build_macos_release.sh \
    --identity "Developer ID Application: Example Corp (TEAMID)" \
    --mode distribution

Get an Apple Development identity:
  1. Open Xcode > Settings > Accounts.
  2. Add or select your Apple ID and development team.
  3. Click Manage Certificates, click +, then choose Apple Development.
  4. Copy the identity name from:
       security find-identity -v -p codesigning
EOF
}

signing_identity=""
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

for command_name in moon codesign security; do
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

if [ -z "$signing_identity" ]; then
  echo "error: an Apple-issued code-signing identity is required via --identity" >&2
  echo "       Run this script with --help for Xcode setup instructions." >&2
  exit 2
fi

find_identity_hashes() {
  security find-identity -v -p codesigning 2>/dev/null | awk \
    -v expected="$signing_identity" '
      {
        hash = $2
        $1 = ""
        $2 = ""
        sub(/^[[:space:]]+/, "", $0)
        if ($0 == "\"" expected "\"") {
          print hash
        }
      }
    '
}

identity_hashes=$(find_identity_hashes)
identity_count=$(printf '%s\n' "$identity_hashes" | awk 'NF { count += 1 } END { print count + 0 }')
if [ "$identity_count" -eq 0 ]; then
  echo "error: no valid code-signing identity named '$signing_identity' was found" >&2
  echo "       Run this script with --help for Xcode setup instructions." >&2
  exit 1
fi
if [ "$identity_count" -gt 1 ]; then
  echo "error: multiple valid code-signing identities named '$signing_identity' were found" >&2
  echo "       Remove the duplicate identity or select a unique identity with --identity." >&2
  exit 1
fi
identity_hash=$(printf '%s\n' "$identity_hashes" | awk 'NF { print; exit }')

validate_apple_signature() {
  signed_path=$1
  signature_context=$2
  signature_details=$(codesign -d --verbose=4 "$signed_path" 2>&1)
  if printf '%s\n' "$signature_details" | grep -q '^Signature=adhoc$'; then
    echo "error: $signature_context is ad-hoc signed" >&2
    exit 1
  fi

  actual_identifier=$(printf '%s\n' "$signature_details" | sed -n 's/^Identifier=//p')
  if [ "$actual_identifier" != "$signing_identifier" ]; then
    echo "error: $signature_context has identifier '$actual_identifier'; expected '$signing_identifier'" >&2
    exit 1
  fi

  signing_authority=$(printf '%s\n' "$signature_details" | sed -n 's/^Authority=//p' | sed -n '1p')
  if [ -z "$signing_authority" ] || [ "$signing_authority" = "(unavailable)" ]; then
    echo "error: signing identity '$signing_identity' has no verifiable Apple signing authority" >&2
    exit 1
  fi

  team_identifier=$(printf '%s\n' "$signature_details" | sed -n 's/^TeamIdentifier=//p')
  if [ -z "$team_identifier" ] || [ "$team_identifier" = "not set" ]; then
    echo "error: signing identity '$signing_identity' has no Apple Team ID" >&2
    exit 1
  fi

  designated_requirement=$(codesign -d -r- "$signed_path" 2>&1)
  case "$designated_requirement" in
    *"anchor apple"*)
      ;;
    *)
      echo "error: signing identity '$signing_identity' is not anchored to Apple" >&2
      exit 1
      ;;
  esac
}

identity_test_dir=$(mktemp -d "${TMPDIR:-/tmp}/aswitch-identity-test.XXXXXX")
cleanup_identity_test() {
  if [ -n "${identity_test_dir:-}" ] && [ -d "$identity_test_dir" ]; then
    rm -rf "$identity_test_dir"
  fi
}
trap cleanup_identity_test EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

identity_test_binary="$identity_test_dir/aswitch-signing-probe"
cp /bin/echo "$identity_test_binary"
if ! codesign \
    --force \
    --sign "$identity_hash" \
    --identifier "$signing_identifier" \
    --timestamp=none \
    "$identity_test_binary" >/dev/null 2>&1; then
  echo "error: failed to sign with identity '$signing_identity'" >&2
  exit 1
fi
validate_apple_signature "$identity_test_binary" "signing probe"
cleanup_identity_test
trap - EXIT HUP INT TERM

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
echo "Signing identity hash: $identity_hash"
echo "Signing identifier: $signing_identifier"

if [ "$signing_mode" = "distribution" ]; then
  codesign \
    --force \
    --sign "$identity_hash" \
    --identifier "$signing_identifier" \
    --options runtime \
    --timestamp \
    "$binary"
else
  codesign \
    --force \
    --sign "$identity_hash" \
    --identifier "$signing_identifier" \
    --timestamp=none \
    "$binary"
fi

codesign --verify --strict --verbose=2 "$binary"
validate_apple_signature "$binary" "release executable"

echo "Signed release: $binary"
