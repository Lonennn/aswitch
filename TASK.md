# Task: Add prefix matching for agent and provider names

## Overview
Enable users to type unique prefixes instead of full names for `set`, `exec`/`run`, and `command` commands. Ambiguous prefixes produce an error listing candidates. The `remove` command is intentionally excluded and still requires exact names.

## Decisions
- **Targets**: Canonical agent names only (not aliases). Provider names.
- **Case sensitivity**: Case-insensitive.
- **Minimum prefix length**: 2 characters.
- **Result type**: Simple `Result[Resolved, String]` (Ok = resolved value, Err = message with candidates).
- **Resolution timing**: At command execution time, not during argument parsing.
- **Success message**: Print "Resolved X 'prefix' to 'Full Name'" when prefix match succeeds.

## Task List

- [x] **Task 1**: Add `resolve_agent_name` to `core/agent/agent.mbt` (removed unused `resolve_agent` per review)
  - `resolve_agent_name(name: String) -> Result[String, String]`: tries exact match via existing `get_canonical_name`, then case-insensitive prefix match on canonical names (min 2 chars). Prints message on prefix match.
  - `resolve_agent(name: String) -> Result[&Agent, String]`: delegates to `resolve_agent_name`, then `create`. Prints message on prefix match.

- [x] **Task 2**: Add `Config::resolve_provider` to `core/config.mbt`
  - `Config::resolve_provider(self, name: String) -> Result[Provider, String]`: tries exact match via existing `get_provider`, then case-insensitive prefix match on provider names (min 2 chars). Prints message on prefix match.

- [x] **Task 3**: Update `cmd/aswitch/command/set_provider.mbt`
  - Replace `get_canonical_name` call with `resolve_agent_name`.
  - Load config inline and resolve provider with `config.resolve_provider` (when explicitly given or from state).
  - Create agent object directly with `@agent.create(canonical_name)` and apply provider directly. Remove the `resolve_temporary_selection` call.
  - Ensure prefix success messages are printed once each for agent and provider.

- [x] **Task 4**: Update `cmd/aswitch/command/temporary_provider.mbt`
  - Update `resolve_agent_from_state` to use `resolve_agent_name` instead of `create` when the user provides an agent name.
  - Update `temporary_command` and `temporary_exec` to resolve explicitly-given provider names with `config.resolve_provider` before passing canonical names to `resolve_temporary_selection`.
  - `resolve_temporary_selection` and `render_temporary_command` remain exact-match-only (they receive canonical names).

- [x] **Task 5**: Add tests
  - Add black-box tests for `resolve_agent_name` in `core/agent/agent_test.mbt` (exact match, prefix match, ambiguous prefix, too-short prefix, unknown agent).
  - Add black-box tests for `Config::resolve_provider` in a new `core/config_test.mbt` (exact match, prefix match, ambiguous prefix, too-short prefix, unknown provider).

- [x] **Task 6**: Validate

## Post-implementation Review Fixes

- [x] **Fix 1**: Removed unused public `resolve_agent` (no callers/tests)
- [x] **Fix 2**: Extracted duplicate config-load + provider-resolve block into `resolve_provider_name` helper in `temporary_provider.mbt`
- [x] **Fix 3**: Fixed misleading error message in `set_provider.mbt` when state references a deleted provider
- [x] **Fix 4**: Replaced magic number `2` with shared constant `@util.MIN_PREFIX_LENGTH`
- [x] **Fix 5**: Removed `println` side effects from domain functions (`resolve_agent_name`, `resolve_provider`); callers now compare input/output and print resolution messages only when a prefix was actually used
  - Run `moon check`
  - Run `moon test`
  - Run `moon fmt`
  - Run `moon info` and review `pkg.generated.mbti` diffs
