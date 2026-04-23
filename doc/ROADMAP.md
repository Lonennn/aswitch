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

## Current State (v0.4.0)

**Implemented:**
- Basic CLI structure with commands: `init`, `providers` (`list`/`ls` alias), `agents`, `set`, `help`, `version`
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

**Limitations:**
- Partial error handling coverage for edge cases
- No shell completion support yet
- No package distribution yet (Homebrew/apt/scoop)

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

### Phase 2: Agent Expansion (Q2 2026) - Current

**Theme: Broaden Ecosystem Support**

| Epic | Hypothesis | Success Metric | Effort |
|------|------------|----------------|--------|
| **✅ OpenCode Support** (Completed 2026-04-21) | We believe that supporting OpenCode will expand our addressable user base by 30% because OpenCode is the second most popular AI coding agent. | Active OpenCode users | M (3-4 weeks) |
| **✅ OpenClaw Support** (Completed 2026-04-21) | We believe that supporting OpenClaw will capture the open-source community segment because OpenClaw is gaining traction in OSS projects. | GitHub stars / mentions | S (2 weeks) |

**Key Deliverables:**
- [x] OpenCode agent implementation
- [x] OpenClaw agent implementation
- [ ] Agent capability detection (auto-discover installed agents)

**Dependencies:** Phase 1 (stable core)

---

### Phase 3: Developer Experience (Q3 2026) - Later

**Theme: Polish & Power User Features**

| Epic | Hypothesis | Success Metric | Effort |
|------|------------|----------------|--------|
| **Shell Integration** | We believe that shell completions and aliases will reduce command execution time by 50% because users currently type full commands. | Command completion usage | S (1-2 weeks) |
| **Provider Presets** | We believe that built-in provider templates will reduce onboarding time from 10 minutes to 2 minutes because users currently lookup provider URLs. | Time to first switch | S (1-2 weeks) |
| **Multi-Agent Sync** | We believe that syncing provider across multiple agents will save power users 5 minutes per switch because they currently manually update each agent. | Multi-agent users | M (3-4 weeks) |
| **Import/Export** | We believe that config portability will improve team adoption because teams currently share configs manually. | Team usage metrics | S (2 weeks) |

**Key Deliverables:**
- [ ] Bash/Zsh/Fish completions
- [ ] Built-in presets for OpenAI, Anthropic, Moonshot, DeepSeek, etc.
- [ ] `sync` command to apply provider to multiple agents
- [ ] `import`/`export` commands for configuration portability
- [ ] Environment-specific profiles (dev/staging/prod)

**Dependencies:** Phase 2 (multiple agents)

---

### Phase 4: Advanced Features (Q4 2026) - Exploration

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
- [ ] Integration with secret managers (1Password, Bitwarden)
- [ ] Generic agent configuration template system
- [ ] Agent-specific environment variable mapping
- [ ] Plugin sandboxing and distribution mechanism

**Dependencies:** Phase 3 (mature product)

---

## Release Timeline

```
Q1 2026 (Completed - Foundation):
├── Runtime Configuration Validation ✅ (Completed 2026-04-17)
├── Backup Safety Rails ✅
├── Dry-Run Safety Rails ✅ (Completed 2026-04-21)
└── Provider Management ✅ (add + remove, completed 2026-04-22)

Q2 2026 (Current - Agent Expansion):
├── OpenCode Agent Support ✅
├── OpenClaw Agent Support ✅
└── Agent capability detection

Q3 2026 (Later - Developer Experience):
├── Shell Completions
├── Provider Presets
├── Multi-Agent Sync
└── Import/Export

Q4 2026 (Exploration - Advanced):
├── Programmatic API
├── Configuration Versioning
├── Team Workspaces
├── Secret Manager Integration
└── Generic Agent Plugin Framework
```

---

## Success Metrics

| Metric | Current | Q1 Target | Q2 Target | Q4 Target |
|--------|---------|-----------|-----------|-----------|
| Supported Agents | 3 | 3 | 3+ | 6+ |
| Supported Providers | ∞ (manual) | ∞ (CLI) | 5 presets | 10 presets |
| Setup Time | 10 min | 2 min | 2 min | 1 min |
| Active Users | TBD baseline | 100 | 500 | 2000 |
| GitHub Stars | TBD baseline | 50 | 200 | 1000 |

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
2. What's the priority order for additional agents (for example Cursor, Copilot, etc.)?
3. Should we support agent-specific configuration beyond environment variables?
4. Is there demand for a Homebrew/apt package distribution?

---

## Immediate Priorities (Next 30-60 Days)

1. Add agent capability detection (auto-discover installed agents).
2. Deliver package distribution (Homebrew first, then apt/scoop).
3. Add shell completions for Bash/Zsh/Fish.

---

## Dependencies & Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Agent config format changes | High | Version detection, graceful degradation |
| Direct config writes corrupt user settings | High | Backup before write, dry-run preview, stronger integration tests |
| MoonBit ecosystem maturity | Medium | Keep dependencies minimal |
| Low adoption | Medium | Focus on developer experience, community engagement |
| Security concerns (API keys) | High | Document security best practices, support secret managers |

---

*Last updated: 2026-04-23*
*Roadmap version: 2.0*
