# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ASwitch is a CLI tool for switching AI agent model providers (Claude Code, OpenCode, OpenClaw, etc.). It manages provider configurations in `aswitch.json` and applies them to agent-specific settings files.

## Common Development Commands

### Build & Run
- Build the CLI: `moon build cmd/aswitch`
- Run the CLI with arguments: `moon run cmd/aswitch -- <command> <args>`
  - Example: `moon run cmd/aswitch -- list`
  - Dry-run example: `moon run cmd/aswitch -- set claude-code OpenAI --dry-run`

### Testing

#### Critical Safety Rule: Environment Isolation
When working with ASwitch during development or testing:
- **Never run write operations against the default system user environment** to avoid accidental modification of real user configuration files for installed AI agents.
- Always use isolated, temporary test environments for all operations that read or write configuration data. Changing the `HOME` environment variable maybe helpful.
- Prefer dry-run mode for all write operations when validating functionality to avoid unnecessary file system modifications.
- Always clean up temporary test resources after testing is complete.

- Run all tests: `moon test`
- Run tests for a specific package: `moon test <directory>`
- Run tests for a specific file: `moon test <file.mbt>`
- Update test snapshots: `moon test --update`
- Generate coverage report: `moon coverage analyze > uncovered.log`

### Code Quality & Validation
- Format all code: `moon fmt`
- Type check without building: `moon check`
- Update public interface files (pkg.generated.mbti): `moon info`

## High-Level Architecture

### Layered Structure
```
┌──────────────────────────────────────────────────┐
│ CLI Layer (cmd/aswitch/)                         │
│  - Command parsing & dispatch                    │
│  - User interaction (interactive add, prompts)   │
│  - Command implementations (add/remove/set etc.) │
├──────────────────────────────────────────────────┤
│ Core Layer (core/)                               │
│  ┌─────────────────────────────────────────────┐ │
│  │ Agent Module (core/agent/)                  │ │
│  │  - Agent trait definition                   │ │
│  │  - Agent implementations:                   │ │
│  │    * ClaudeCode, OpenCode, OpenClaw         │ │
│  │  - Handles agent-specific config file I/O   │ │
│  │  - Dry-run diff generation                  │ │
│  │  - Agent detection utilities                │ │
│  └─────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────┐ │
│  │ Config Module (core/config.mbt)             │ │
│  │  - Load/save aswitch.json config            │ │
│  │  - Config path resolution (env var → home)  │ │
│  └─────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────┐ │
│  │ Provider Module (core/provider/)            │ │
│  │  - Provider and Model data structures       │ │
│  └─────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────┐ │
│  │ Validation Module (core/validation.mbt)     │ │
│  │  - Config validation logic                  │ │
│  └─────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

### Key Patterns & Conventions
1. **Agent Trait**: All AI agents implement the `Agent` trait, which defines `name()`, `apply_provider()`, and `get_provider_diff()` methods. New agents can be added by implementing this trait and updating the `create()` factory function.
2. **Dry-Run Support**: The `get_provider_diff()` method generates a JSON diff of changes without modifying files, enabled via the `--dry-run`/`-n` flag on the `set` command.
3. **Configuration Safety**: All config changes are validated before being applied to agent files, preventing invalid configurations from breaking AI agents.
4. **Command Organization**: Each CLI command has its own implementation file in `cmd/aswitch/command/`, with shared logic in `command.mbt`.

### Configuration Locations
- `aswitch.json` is loaded in this priority:
  1. `$ASWITCH_HOME/aswitch.json` (if environment variable is set)
  2. `$HOME/aswitch.json` (Unix/macOS) or `$USERPROFILE/aswitch.json` (Windows)
  3. `./aswitch.json` (current directory fallback)

## MoonBit Project Conventions (from AGENTS.md)
- Code is organized in blocks separated by `///|`; block order is irrelevant.
- Each directory is a MoonBit package with a `moon.pkg` file listing dependencies.
- Tests: 
  - Black-box tests: `*_test.mbt` (test public APIs)
  - White-box tests: `*_wbtest.mbt` (test internal implementation)
- Before submitting changes: Run `moon info && moon fmt` to update interfaces and format code. Check diffs of `pkg.generated.mbti` to verify public API changes are intended.
