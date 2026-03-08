# lonen44/aswitch

Switch AI Agent model config.

## Configuration

ASwitch stores configuration in `aswitch.json`. The location is determined in this order:

1. `$ASWITCH_HOME/aswitch.json` - if `ASWITCH_HOME` environment variable is set
2. `$HOME/aswitch.json` - on Unix/macOS
3. `$USERPROFILE/aswitch.json` - on Windows
4. `./aswitch.json` - current directory (fallback)

### JSON Schema

A [JSON Schema](./core/aswitch.schema.json) is provided for editor autocomplete and validation.

To enable IntelliSense in your editor, add the `$schema` property to your config file:

```json
{
  "$schema": "./core/aswitch.schema.json",
  "providers": [
    {
      "name": "OpenAI",
      "api_key": "sk-...",
      "openai_base_url": "https://api.openai.com/v1",
      "models": ["gpt-4", "gpt-3.5-turbo"]
    }
  ]
}
```

### Editor Support

- **VS Code**: Automatic IntelliSense when `$schema` is present
- **JetBrains IDEs**: JSON schema support via Settings → Languages & Frameworks → Schemas
- **Vim/Neovim**: Use [jsonschema](https://github.com/jeffzip/json-schema.nvim) or similar plugins

### Example Configuration

See [aswitch.example.json](./aswitch.example.json) for a complete example.

### Provider Configuration

Each provider requires:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Display name/alias |
| `api_key` | string | yes | API key for authentication |
| `models` | string[] | yes | List of model names |
| `openai_base_url` | string | no | OpenAI-compatible API endpoint |
| `anthropic_base_url` | string | no | Anthropic-compatible API endpoint |
