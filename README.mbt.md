# lonen44/aswitch

Switch model providers across AI agent CLIs (Claude Code, OpenCode, OpenClaw) from one central config.

## Build and Run

```bash
# run directly
moon run cmd/aswitch -- help

# build native binary
moon build --release
```

### Signed macOS Release

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

## Supported Agents

- `claude-code` (aliases: `claude`, `claudecode`)
- `opencode` (aliases: `open-code`)
- `openclaw` (aliases: `open-claw`)

Use `aswitch agents` to print the current supported list.

## CLI Commands

```text
aswitch init
aswitch providers
aswitch agents
aswitch set <agent> [provider] [openai|anthropic] [--dry-run|-n]
aswitch run [agent] [provider] [--api-format openai|anthropic] [--print-command] [-- <args...>]
aswitch command [agent] [provider] [--api-format openai|anthropic] [--raw]
aswitch add
aswitch add <name> <api_key> <base_url> <model>
aswitch add --name <name> --api-key <key> --model <model> \
  [--openai-base-url <url>] [--anthropic-base-url <url>]
aswitch remove|rm <name>
aswitch help
aswitch version
```

Examples:

```bash
aswitch init
aswitch add openai sk-xxx https://api.openai.com/v1 gpt-4.1
aswitch add --name anthropic --api-key sk-ant-xxx --model claude-sonnet-4-5 \
  --anthropic-base-url https://api.anthropic.com
aswitch set claude-code anthropic
aswitch set open-code openai openai --dry-run
aswitch remove openai
```

### Usage State Memory

`aswitch` remembers the last used agent and provider in `~/.aswitch/state.json`.
After the first explicit invocation, subsequent commands can omit arguments:

```bash
# First: explicit set
aswitch set claude-code anthropic

# Later: omit provider (uses last provider for claude-code)
aswitch set claude-code

# Run with explicit args
aswitch run claude-code anthropic -- claude

# Later: omit both (uses last agent and its last provider)
aswitch run -- claude
```

The `run` command is the fastest way to start an agent with a temporary
provider override without modifying any config files. The `command`
subcommand shows the resolved agent, provider, API format, and shell command
without executing it. Use `--raw` when a caller needs only the shell command on
stdout for scripting.

## Configuration

`aswitch` stores providers in `aswitch.json`. Path resolution order:

1. `$ASWITCH_HOME/aswitch.json` (if `ASWITCH_HOME` is set)
2. `$HOME/aswitch.json` (Unix/macOS)
3. `$USERPROFILE/aswitch.json` (Windows)
4. `./aswitch.json` (fallback)

### JSON Schema

Schema file: [`asset/aswitch.schema.json`](./asset/aswitch.schema.json)

To enable editor IntelliSense, add `$schema` in `aswitch.json`:

```json
{
  "$schema": "./asset/aswitch.schema.json",
  "providers": [
    {
      "name": "OpenAI",
      "api_key": "sk-...",
      "openai_base_url": "https://api.openai.com/v1",
      "models": [{ "name": "gpt-4.1" }]
    }
  ]
}
```

See [`aswitch.example.json`](./aswitch.example.json) for a complete example.

### Provider Fields

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | string | yes | Provider alias used by `aswitch set` |
| `api_key` | string | yes | API key |
| `models` | object[] | yes | Model list, each object requires `name` |
| `openai_base_url` | string | no | OpenAI-compatible endpoint |
| `anthropic_base_url` | string | no | Anthropic-compatible endpoint |

At least one of `openai_base_url` / `anthropic_base_url` is required.

## Validation and Safety

- Config is validated before write/apply.
- Duplicate provider names are rejected (case-insensitive).
- `set --dry-run` prints file diffs without writing.
- Before any file write, backups are rotated as `<file>.bak.1` ... `<file>.bak.5`.

## Shell Completion

See the complete [Shell Completion Installation Guide](./docs/shell-completions.md) for instructions on installing completions for Zsh, PowerShell, and other supported shells.
