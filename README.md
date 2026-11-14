# Claude–Codex Supervisor Relay

**Public Agent Skill — ChatGPT-led workflow, Claude implementation, Codex audit.**

This project defines the intended orchestration model:

- **ChatGPT is the project orchestrator.** It receives the user's goal, breaks work into bounded tasks, chooses whether the next task goes to Claude or Codex, reads reports, evaluates findings, and decides the next technical step.
- **Claude Code is the primary developer.** It implements the task assigned by ChatGPT, runs permitted tests, and returns a structured report.
- **OpenAI Codex CLI is the independent auditor.** It reviews only when ChatGPT routes an audit task, uses a read-only sandbox, and never applies fixes.
- **The user is Product Owner.** Product decisions and sensitive approvals remain with the user.

## Intended end-to-end cycle

```text
User → ChatGPT (orchestrator) → private GitHub task inbox
                                  ↓
                            local Windows worker
                                  ↓
                         selected agent: Claude or Codex
                                  ↓
                         report back to private inbox
                                  ↓
                         ChatGPT evaluates the report
                                  ↓
                      next task: Claude / Codex / PO
```

ChatGPT decides after each report whether to ask Claude to implement/correct, ask Codex to audit, ask either agent for focused verification, or report the outcome to the PO. Agent recommendations do not trigger the next step on their own.

## Important current status

This repository currently contains the public Agent Skill and a Windows Skill installer. The separate private inbox contains task templates and protocol notes. **The local relay worker and live ChatGPT ↔ Claude/Codex round trip are not yet implemented or validated.** This repository must not be described as an operational automatic relay until the real Windows worker, agent dispatch (`claude` versus `codex`), report return, permissions, and end-to-end tests have been completed.

The public Skill enforces the role separation inside Claude Code. By itself, it cannot make ChatGPT send prompts to the user's local computer or automatically receive reports.

## Install the Skill on Windows

Requirements: Git and Claude Code installed.

```powershell
git clone https://github.com/warclock89/claude-codex-supervisor-relay.git
cd claude-codex-supervisor-relay
.\scripts\install-skill.ps1
```

The installer copies the Skill to `%USERPROFILE%\.claude\skills\claude-codex-supervisor`. It refuses to overwrite an existing installation.

## Manual install on macOS/Linux

Clone this repository and copy `skills/claude-codex-supervisor` into `~/.claude/skills/`.

## Safety defaults

- Claude remains the implementer; Codex is read-only.
- ChatGPT determines task routing and the next workflow step.
- No clean Git baseline is required; pre-existing modified/untracked work must be preserved.
- No automatic Git add, commit, push, fetch, stash, reset, checkout, clean, rebase, or merge.
- No unbounded correction loops or out-of-scope fixes.
- Supabase, SQL writes, migrations, secrets, credentials, deployments, and production operations require separate explicit authorization.

## Tests and validation

The Skill's behavior and installation have not yet been validated end-to-end across a real ChatGPT-to-Windows-worker-to-Claude/Codex connection. Follow the local setup instructions and test only in a disposable, non-production project before relying on the system.

## License

No open-source license has been selected yet. Until a license is added, do not assume public availability grants permission to redistribute or modify the contents.

