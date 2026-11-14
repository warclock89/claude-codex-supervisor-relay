# Claude–Codex Supervisor Relay

**Experimental open-source kit — v0.1.3**

Claude remains the primary developer. Codex is an independent, read-only auditor. A local Windows worker can carry tasks from a private GitHub issue queue to Claude Code and return Claude's report as an issue comment, so prompts and reports do not need to be copied manually.

## Roles

- **ChatGPT / coordinator:** creates scoped tasks in the private queue, reads returned reports, and prepares follow-up work.
- **Claude Code / primary developer:** analyzes requirements, implements only PO-authorized changes, runs permitted tests, asks Codex for an independent review, validates Codex findings, and writes the final report.
- **OpenAI Codex CLI / auditor:** reviews the exact task scope in a read-only sandbox; it does not implement or modify project files.
- **Product Owner:** retains all product decisions and sensitive-operation approvals.
- **Local worker:** transports issues and reports. It does not make product decisions.

## Architecture

```text
ChatGPT → private GitHub issue queue → local Windows worker → Claude Code
                                                           ↓
                                                Codex CLI (read-only audit)
                                                           ↓
ChatGPT ← report comment ← worker ← Claude validates findings and completes task
```

## Quick start

Requirements: Windows, Node.js 20+, Git, GitHub CLI (`gh`), Claude Code CLI, Codex CLI, and completed authentication for each CLI.

1. Create a **separate private** GitHub repository for the task queue. Do not use a product repository.
2. Clone this public repository.
3. Install the Skill and worker from PowerShell:

   ```powershell
   .\scripts\install-skill.ps1
   .\scripts\install-worker.ps1
   ```

4. Configure `%LOCALAPPDATA%\ClaudeCodexBridge\config.json` using `bridge/config.example.json`. Keep `allowImplementation` false initially, and set only explicitly approved local project paths and allowed authors.
5. Create the queue labels listed in `bridge/README.md`.
6. Run the self-test and dry-run exactly as documented in `bridge/README.md`. Do not enable polling until the read-only round trip has been reviewed.

## Safety defaults

- Codex is launched with a read-only sandbox.
- Claude is the only developer; Codex never applies its findings.
- The worker does not perform Git history writes: no add, commit, push, fetch, stash, reset, checkout, clean, rebase, or merge.
- Implementation mode is disabled by default and requires both a local configuration switch and an explicit PO approval in the task, plus a non-empty path allowlist.
- No Supabase, database, secret, deployment, or migration operation is implicitly authorized.
- The private queue is required. Task prompts and reports may contain internal project information.
- The worker is experimental. Path allowlists and Claude Code permissions are not a substitute for OS-level isolation. Review the code and local permissions before enabling implementation mode.

## Tests and validation

The included automated Node test suite passed **14/14** in the development environment. The integration test uses mocked GitHub, Claude, and Codex CLI processes. It is not a live test of the user's Windows machine, GitHub account, Claude Code, or Codex CLI. A real end-to-end installation must be validated locally before relying on the relay.

See:
- `skills/claude-codex-supervisor/SKILL.md` — Claude/Codex collaboration rules.
- `bridge/README.md` — Windows worker setup and queue format.
- `docs/chatgpt-github-transport.md` — GitHub connector transport and limitations.
- `SECURITY.md` — reporting security issues.

## License

MIT. See [LICENSE](LICENSE).
