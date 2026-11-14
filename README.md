# Claude–Codex Supervisor Skill

**Public Agent Skill for Claude Code**

This repository publishes an Agent Skill that keeps **Claude Code as the primary developer** and uses **OpenAI Codex CLI as an independent read-only auditor**.

## Roles

- Claude Code analyzes requirements, implements the authorized work, runs permitted tests, reviews Codex findings, and prepares the final report.
- Codex independently inspects the exact change set in a read-only sandbox. It does not implement fixes or change project files.
- The Product Owner retains product decisions and all sensitive-operation approvals.
- ChatGPT can coordinate tasks and analyze reports, but this Skill alone does not create a live ChatGPT-to-Claude desktop connection.

## Install on Windows

Requirements: Git and Claude Code installed.

```powershell
git clone https://github.com/warclock89/claude-codex-supervisor-relay.git
cd claude-codex-supervisor-relay
.\scripts\install-skill.ps1
```

The installer copies the Skill to `%USERPROFILE%\.claude\skills\claude-codex-supervisor`. It refuses to overwrite an existing installation.

## Manual install on macOS/Linux

Clone this repository and copy `skills/claude-codex-supervisor` into `~/.claude/skills/`.

Restart or refresh Claude Code's Skill discovery if the Skill does not appear.

## Safety design

- Claude remains the developer; Codex is read-only.
- No clean Git baseline is required; pre-existing dirty/untracked work must be preserved.
- No automatic Git add, commit, push, fetch, stash, reset, checkout, clean, rebase, or merge.
- No automatic loops or out-of-scope fixes.
- Supabase, SQL writes, migrations, secrets, credentials, deployments, and production operations require their own explicit authorization.

## Scope and current status

This public repository currently contains the **Agent Skill** and a safe Windows installer. It does not yet contain a validated local Windows relay worker, and it does not automatically transport tasks between ChatGPT and Claude Code. A separate private GitHub inbox repository has been prepared for a future relay implementation.

The Skill has been published to GitHub. A complete live test on a user's Windows installation, Claude Code, and Codex CLI has not yet been completed.

## License

No open-source license has been selected yet. Until a license is added, do not assume that public availability grants permission to redistribute or modify the contents.

