# Building ASwitch

For CLI usage and configuration, see the [README](../README.mbt.md).
Run the commands below from the repository root.

## Build and Run

```bash
# run directly
moon run cmd/aswitch -- help

# build native binary
moon build --release
```

## Signed macOS Release

Persistent Keychain access across rebuilt executables requires an Apple-issued
code-signing identity, such as an Apple Development certificate created by
Xcode. Pass that identity explicitly:

```bash
scripts/build_macos_release.sh \
  --identity "Apple Development: Example Developer (TEAMID)"
```

Create an Apple Development identity in Xcode under **Settings > Accounts >
Manage Certificates**, then use
`security find-identity -v -p codesigning` to get its exact name. The release
script verifies the identity has an Apple trust anchor and Team ID before
building.

For a distributable Developer ID build, enable hardened runtime and
timestamping:

```bash
scripts/build_macos_release.sh \
  --identity "Developer ID Application: Example Corp (TEAMID)" \
  --mode distribution
```

For local development without an Apple-issued identity, use `moon build` or
`moon run` and supply credentials through provider-specific environment
variables instead of storing them in the Keychain. For example:

```bash
export ASWITCH_ZEGO_API_KEY='your-api-key'
moon run src/cmd/aswitch -- command claude zego
```

If an API key was stored by an older build, clear the old ASwitch credentials
and add the providers again using the Apple-signed binary:

```bash
scripts/clear_macos_keychain.sh
```

The clearing script removes only generic-password items whose Keychain service
is `aswitch`; it does not modify `aswitch.json` or the signing identity. Use
`--yes` to skip its confirmation prompt.

To list providers with keys in the Keychain, run
`scripts/show_macos_keychain.sh`. Pass `--reveal` to print the key values.
Revealed values are written to stdout. This does not show environment
variables or keys stored in `aswitch.json`.

The signed executable is written to
`_build/native/release/build/cmd/aswitch/aswitch.exe`. Override its stable
identifier when needed:

```bash
scripts/build_macos_release.sh \
  --identity "Apple Development: Example Developer (TEAMID)" \
  --identifier "dev.example.aswitch"
```
