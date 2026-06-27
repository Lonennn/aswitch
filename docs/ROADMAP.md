# ASwitch Roadmap

## Strategic Overview

ASwitch is a command-line tool for switching AI model providers across multiple AI coding agents (Claude Code, OpenCode, OpenClaw, etc.). This roadmap outlines the evolution from the current MVP to a mature, widely-adopted developer tool.

---

## Business Outcomes

1. **Developer Adoption** - Become the de facto standard for AI agent provider management
2. **Cross-Platform Compatibility** - Support all major operating systems (macOS, Linux, Windows)
3. **Ecosystem Coverage** - Support all major AI coding agents and model providers
4. **Developer Experience** - Simple, intuitive CLI that "just works"

---

## Current State (v0.6.0)

**Implemented:**
- Basic CLI structure with commands: `init`, `providers` (`list`/`ls` alias), `agents`, `set`, `exec` (`run` alias), `help`, `version`
- Provider add command support: `add` (interactive and argument-based)
- Provider remove command support: `remove`
- Configuration file management (`aswitch.json`)
- Claude Code agent support (~/.claude/settings.json)
- OpenCode agent support (~/.config/opencode/opencode.json)
- OpenClaw agent support (~/.openclaw/openclaw.json)
- Provider configuration with API keys, base URLs, and extended model configuration (context limits, modalities)
- Cross-platform path detection (Unix/macOS/Windows)
- JSON schema provided for editor IntelliSense and manual validation workflows
- Switch command supports optional API format parameter (openai/anthropic) for OpenCode and OpenClaw agents
- Improved error handling with descriptive error messages
- Add-provider workflow now creates `aswitch.json` backups before save
- CLI runtime migrated to async and native/llvm targets
- Agent capability detection (auto-discovers installed agents, groups them in `agents` command output)

**Limitations:**
- Partial error handling coverage for edge cases
- No shell completion support yet
- No package distribution yet (Homebrew/apt/scoop)
- API keys stored in cleartext in `aswitch.json` — Phase 4 at-rest encryption will secure the canonical store; agent configs may still receive cleartext until Phase 5 environment-variable support

---

## Roadmap

### Phase 1: Foundation (Q1 2026) - Completed

**Theme: Safe Writes & Core Stability**

| Epic | Hypothesis | Success Metric | Effort |
|------|------------|----------------|--------|
| **✅ Runtime Configuration Validation** (Completed 2026-04-17) | We believe that validating configuration before any write or apply operation will reduce configuration errors by 90% because malformed or incomplete configs currently fail late. | Error rate reduction | S (1-2 weeks) |
| **✅ Safe Modification Workflow** (100% complete - Backup ✅, Dry-run ✅, Completed 2026-04-21) | We believe that backup and dry-run support will reduce destructive mistakes because `set` currently writes directly to agent config files. | Failed switch recovery rate | S (1-2 weeks) |
| **✅ Provider Management** (Completed 2026-04-22: `add` + `remove`) | We believe that adding runtime provider CRUD operations after validation and backup support will reduce manual JSON editing by 80% without increasing support burden. | % of users using CLI vs manual editing | M (3-4 weeks) |

**Key Deliverables:**
- [x] ✅ Add runtime configuration validation before `set` and future mutating commands (Completed 2026-04-17)
- [x] ✅ Configuration backup before modifications
- [x] ✅ Dry-run mode for switch operations (Completed 2026-04-21)
- [x] ✅ Implement `remove` command (completed 2026-04-22)
- [x] ✅ Implement `add` command (interactive + argument mode, completed 2026-04-22)
- [x] ✅ Backup `aswitch.json` before add-provider saves (completed 2026-04-22)
- [x] ✅ Expand command and integration tests around mutating workflows (`add` path, completed 2026-04-22)

**Dependencies:** None

---

### Phase 2: Agent Expansion (Q2 2026) - Completed

**Theme: Broaden Ecosystem Support**

| Epic | Hypothesis | Success Metric | Effort |
|------|------------|----------------|--------|
| **✅ OpenCode Support** (Completed 2026-04-21) | We believe that supporting OpenCode will expand our addressable user base by 30% because OpenCode is the second most popular AI coding agent. | Active OpenCode users | M (3-4 weeks) |
| **✅ OpenClaw Support** (Completed 2026-04-21) | We believe that supporting OpenClaw will capture the open-source community segment because OpenClaw is gaining traction in OSS projects. | GitHub stars / mentions | S (2 weeks) |
| **✅ Agent Capability Detection** (Completed 2026-04-24) | We believe that auto-detecting installed agents improves user experience by eliminating the need for users to remember which agents they have set up. | User satisfaction / support queries | S (1 week) |

**Key Deliverables:**
- [x] OpenCode agent implementation
- [x] OpenClaw agent implementation
- [x] Agent capability detection (auto-discover installed agents, groups output by installation status)

**Dependencies:** Phase 1 (stable core)

---

### Phase 3: Developer Experience (Q3 2026) - Current

**Theme: Polish & Power User Features**

| Epic | Hypothesis | Success Metric | Effort |
|------|------------|----------------|--------|
| **✅ Shell Integration** (Zsh & PowerShell completed 2026-04-28) | We believe that shell completions and aliases will reduce command execution time by 50% because users currently type full commands. | Command completion usage | S (1-2 weeks) |
| **✅ Temporary Provider Override** (Completed 2026-04-24) | We believe that non-persistent provider overrides will unlock one-off tasks, CI jobs, and per-command experimentation because `set` currently rewrites agent config files even when the user only needs a temporary switch. | % of switches done without file writes | M (2-3 weeks) |
| **Codex Support** | We believe that supporting Codex will expand ASwitch coverage for OpenAI-native coding workflows because users who switch between Claude Code, OpenCode, OpenClaw, and Codex should be able to manage provider selection from the same config. | Active Codex users / successful switches | M (2-3 weeks) |
| **Unset Command** | We believe that an `unset` command will make provider switching safer and more reversible because users need a first-class way to remove ASwitch-managed provider settings from an agent without manually editing JSON files. | Successful restore/unset operations | S (1-2 weeks) |

**Key Deliverables:**
- [x] Zsh completions (completed 2026-04-28)
- [x] PowerShell completions (completed 2026-04-28)
- [ ] Bash/Fish completions
- [x] Temporary provider override workflow for one command or one shell session (`command` / `exec`, completed 2026-04-24)
- [x] Remember last used provider: `set`, `exec` (`run`), and `command` commands recall the previously used agent and provider from `~/.aswitch/state.json` so subsequent invocations do not require these arguments (completed 2026-05-25)
- [x] Agent and provider name prefix matching for `set`, `exec` (`run`), and `command` commands: users can type unique prefixes instead of full names (e.g., `clau` resolves to `claude-code`, `ope` resolves to `open-code` if unambiguous; ambiguous prefixes produce an error listing candidates) (completed 2026-05-31)
- [ ] Codex agent implementation with provider apply, dry-run diff, detection, aliases, and temporary override support
- [ ] `unset` command to remove ASwitch-managed provider settings from an agent, with backup, dry-run preview, and state cleanup

**Dependencies:** Phase 2 (multiple agents)

---

### Phase 4: Security & Secrets (Q4 2026)

**Theme: Protect Sensitive Configuration**

| Epic | Hypothesis | Success Metric | Effort |
|------|------------|----------------|--------|
| **At-Rest API Key Encryption** | We believe that encrypting API keys at rest will eliminate the single largest security risk in ASwitch and increase user trust, because currently API keys are stored in plaintext where any process with user file access can read them, and users are rightly hesitant to back up or version-control their configs. Encryption protects against accidental disclosure and backup leaks; agent config files may still receive cleartext until Phase 5 environment-variable support. | Security audit pass / backup confidence | M (3-4 weeks) |
| **Secret Manager Integration** | We believe that integrating with password managers (1Password, Bitwarden) will increase enterprise adoption because security-conscious teams prefer to store secrets in dedicated vaults rather than local keychains. | Enterprise sign-ups | M (3-4 weeks) |
| **Agent Environment Variable Mapping** | We believe that injecting provider credentials via environment variables will eliminate the need to write cleartext API keys to agent config files, closing the final gap in our security model. | % of switches done without file writes | M (3-4 weeks) |

**Key Deliverables:**
- [ ] OS-native credential store integration (macOS Keychain, Windows Credential Manager, Linux libsecret/Secret Service) to host the encryption key
- [ ] Field-level AES-256-GCM encryption of `apiKey` values in `aswitch.json` with transparent encrypt-on-save / decrypt-on-load
- [ ] Automatic migration: detect and encrypt existing cleartext API keys on first load without user action
- [ ] Graceful fallback when OS keychain is unavailable (password-derived key with PBKDF2, or cleartext mode with explicit security warning)
- [ ] Documented threat model: protects canonical config against accidental commits, backup leaks, and passive file-system access; active user-account compromise requires Phase 5 env-var support for full mitigation
- [ ] Integration with secret managers (1Password, Bitwarden)
- [ ] Agent-specific environment variable mapping
- [x] Safe command display via temporary terminal buffer: `command` and `exec --print-command` render the temporary shell command in an ephemeral terminal view when stdout is a TTY, preventing API keys from leaking into terminal scrollback history. On POSIX systems this routes through a pager subprocess (`$PAGER` or a platform-appropriate default such as `less`); on Windows it uses the Windows Terminal alternate screen buffer when available. Falls back to direct stdout with a warning when piped or redirected, or when the temporary buffer backend is unavailable (completed 2026-06-14)

**Dependencies:** Phase 3 (mature UX)

---

### Phase 5: Advanced Features (Q1 2027) - Exploration

**Theme: Enterprise & Power Users**

| Epic | Hypothesis | Success Metric | Effort |
|------|------------|----------------|--------|
| **Provider Switching API** | We believe that a programmatic API will enable CI/CD integration because teams want to switch providers in automated workflows. | API usage | L (6-8 weeks) |
| **Configuration Versioning** | We believe that config history will reduce rollback time from 30 minutes to 1 minute because users currently manually undo changes. | Rollback usage | M (3-4 weeks) |
| **Team Workspaces** | We believe that shared team configurations will improve enterprise adoption because current configs are individual-only. | Enterprise sign-ups | L (6-8 weeks) |
| **Generic Agent Plugin Framework** | We believe that a plugin-style agent framework will enable community contributions because maintainers can't support every new agent. | Community-contributed agents | L (6-8 weeks) |

**Key Deliverables:**
- [ ] Library API for programmatic usage
- [ ] Configuration versioning with rollback
- [ ] Team workspace support
- [ ] Audit logging for provider switches
- [ ] Generic agent configuration template system
- [ ] Plugin sandboxing and distribution mechanism

**Dependencies:** Phase 4 (security fundamentals)

---

## Release Timeline

```
Q1 2026 (Completed - Foundation):
├── Runtime Configuration Validation ✅ (Completed 2026-04-17)
├── Backup Safety Rails ✅
├── Dry-Run Safety Rails ✅ (Completed 2026-04-21)
└── Provider Management ✅ (add + remove, completed 2026-04-22)

Q2 2026 (Completed - Agent Expansion):
├── OpenCode Agent Support ✅
├── OpenClaw Agent Support ✅
└── Agent capability detection ✅ (Completed 2026-04-24)

Q3 2026 (Current - Developer Experience):
├── Shell Completions (Zsh ✅, PowerShell ✅, Bash/Fish pending)
├── Provider Presets
├── Codex Agent Support
├── Unset Command
└── Temporary Provider Override ✅ (Completed 2026-04-24)

Q4 2026 (Security & Secrets):
├── At-Rest API Key Encryption
├── Secret Manager Integration
└── Agent Environment Variable Mapping

Q1 2027 (Exploration - Advanced):
├── Programmatic API
├── Configuration Versioning
├── Team Workspaces
└── Generic Agent Plugin Framework
```

---

## What's NOT on the Roadmap

**Explicitly Deferred:**
- GUI/Web interface (staying CLI-first)
- Cloud/sync service (local-first philosophy)
- Provider billing/management (out of scope)
- Model performance comparison (out of scope)

**Why:** Maintaining focus on the core value proposition: simple, fast provider switching.

---

## Open Questions

1. Should we support non-OpenAI-compatible API formats natively?
2. What's the priority order for additional agents after Codex (for example Cursor, Copilot, etc.)?
3. Which agents can be reliably driven by environment variables alone, and which still require file-based writes for full support?
4. Is there demand for a Homebrew/apt package distribution?

---

## Immediate Priorities (Next 30-60 Days)

1. Deliver package distribution (Homebrew first, then apt/scoop).
2. Add Codex agent support.
3. Add `unset` command support.
4. Add shell completions for Bash/Fish (Zsh & PowerShell already complete).
5. Add built-in provider presets for common model providers (OpenAI, Anthropic, Moonshot, DeepSeek, etc.).

---

## Dependencies & Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Agent config format changes | High | Version detection, graceful degradation |
| Direct config writes corrupt user settings | High | Backup before write, dry-run preview, stronger integration tests |
| MoonBit ecosystem maturity | Medium | Keep dependencies minimal |
| Low adoption | Medium | Focus on developer experience, community engagement |
| Security concerns (API keys stored in cleartext) | High | Phase 4 at-rest encryption with OS keychain-backed keys; Phase 5 env-var injection to avoid writing cleartext to agent configs |

---

*Last updated: 2026-06-28*
*Roadmap version: 2.8*
