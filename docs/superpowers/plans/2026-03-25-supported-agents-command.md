# Supported Agents Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add explicit `providers` and `agents` CLI commands while keeping `list` and `ls` as backward-compatible aliases for configured providers.

**Architecture:** Extend command parsing and dispatch with a new supported-agents command and rename the provider-listing primary command at the help surface. Keep canonical supported agent names in `core/agent` so display logic does not drift from agent creation support.

**Tech Stack:** MoonBit CLI packages, whitebox tests, `moon test`, `moon info`, `moon fmt`

---

### Task 1: Pin Down CLI Parsing

**Files:**
- Create: `cmd/aswitch/command/command_wbtest.mbt`
- Modify: `cmd/aswitch/command/command.mbt`
- Test: `cmd/aswitch/command/command_wbtest.mbt`

- [ ] **Step 1: Write the failing tests**

Write tests that verify:
- `parse_args(["providers"])` maps to the provider-listing command
- `parse_args(["list"])` and `parse_args(["ls"])` still map to the provider-listing command
- `parse_args(["agents"])` maps to the supported-agents command

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test cmd/aswitch/command`
Expected: FAIL because the new command variant and parser branch do not exist yet.

- [ ] **Step 3: Write minimal implementation**

Add the new command enum variant and parser branches needed to satisfy the tests.

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test cmd/aswitch/command`
Expected: PASS for the parser tests.

### Task 2: Pin Down Supported Agent Names

**Files:**
- Create: `core/agent/agent_wbtest.mbt`
- Modify: `core/agent/agent.mbt`
- Test: `core/agent/agent_wbtest.mbt`

- [ ] **Step 1: Write the failing test**

Write a test that verifies the canonical supported agent list is exactly:
- `claude-code`
- `open-code`
- `openclaw`

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test core/agent`
Expected: FAIL because the public function exposing canonical names does not exist yet.

- [ ] **Step 3: Write minimal implementation**

Add a public function in `core/agent/agent.mbt` that returns the canonical supported agent names.

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test core/agent`
Expected: PASS for the supported-agent-name test.

### Task 3: Wire the Command Handlers and Help Text

**Files:**
- Create: `cmd/aswitch/command/list_agents.mbt`
- Modify: `cmd/aswitch/aswitch.mbt`
- Modify: `cmd/aswitch/command/help.mbt`
- Modify: `cmd/aswitch/command/pkg.generated.mbti`
- Test: `moon test`

- [ ] **Step 1: Write the minimal command implementation**

Implement the `agents` handler using the canonical list from `core/agent` and update CLI dispatch to call it.

- [ ] **Step 2: Update the help text**

Document `providers` and `agents`, and mention `list`/`ls` only as aliases for providers.

- [ ] **Step 3: Run focused tests**

Run: `moon test cmd/aswitch/command && moon test core/agent`
Expected: PASS.

- [ ] **Step 4: Run full verification**

Run: `moon test`
Expected: PASS.

- [ ] **Step 5: Refresh generated interfaces and formatting**

Run: `moon info && moon fmt`
Expected: generated `.mbti` files and formatting reflect the intended public API change.
