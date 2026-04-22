# lonen44/aswitch

Switch model providers across AI agent CLIs (Claude Code, OpenCode, OpenClaw) from one central config.

## Build and Run

```bash
# run directly
moon run cmd/aswitch -- help

# build native binary
moon build --release
```

## Supported Agents

- `claude-code` (aliases: `claude`, `claudecode`)
- `open-code` (aliases: `opencode`, `open-code`)
- `openclaw` (aliases: `openclaw`, `open-claw`)

Use `aswitch agents` to print the current supported list.

## CLI Commands

```text
aswitch init
aswitch providers
aswitch agents
aswitch set <agent> <provider> [openai|anthropic] [--dry-run|-n]
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
