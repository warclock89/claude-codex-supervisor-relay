# Claude–Codex Supervisor Relay

**Governance Skill for a ChatGPT-led workflow, using Agent Bridge as the transport and local execution layer.**

This repository defines orchestration policy. It does not reimplement an MCP broker or local CLI worker.

## Combined architecture

| Layer | Component | Responsibility |
|---|---|---|
| Orchestration | ChatGPT | Scopes tasks, chooses the next agent, evaluates reports, and decides the next step. |
| Governance | This Supervisor Skill | Preserves role hierarchy, evidence standards, project safeguards, and PO approval boundaries. |
| Transport and queue | [Agent Bridge](https://github.com/jcharveyjr/claude-chatgpt-agent-bridge) | MCP server, asynchronous tasks, local CLI workers, result retrieval, and cancellation. |
| Implementation | Claude Code | Primary developer; implements bounded tasks assigned by ChatGPT. |
| Independent review | OpenAI Codex CLI | Read-only auditor; never applies its own findings. |
| Product authority | User | Product Owner; owns product decisions and sensitive approvals. |

~~~text
User / Product Owner
        |
        v
ChatGPT — project orchestrator
        |  delegate_task(source_agent="chatgpt")
        v
Agent Bridge — local MCP broker + persistent task queue
        |                                  |
        v                                  v
Claude Code worker                    Codex CLI worker
(implementation)                      (read-only audit)
        |                                  |
        +--------------- result -----------+
                         |
                         v
                  get_task(task_id)
                         |
                         v
              ChatGPT evaluates evidence
                         |
             chooses Claude / Codex / PO
~~~

ChatGPT submits tasks and retrieves results through MCP. The user does not copy prompts or reports between agents during the intended normal workflow.

## Why this combination

Agent Bridge already supplies the transport primitives this repository originally planned to build: a local MCP server, asynchronous queue, Claude and Codex CLI adapters, task retrieval, cancellation, named workspaces, and permission modes. Rebuilding those components here would duplicate functionality.

This repository remains the **policy layer**. Agent Bridge remains a separate upstream project; its source is not copied or represented as our code.

## Setup overview

Follow the upstream [Agent Bridge README](https://github.com/jcharveyjr/claude-chatgpt-agent-bridge) and [User Guide](https://github.com/jcharveyjr/claude-chatgpt-agent-bridge/blob/main/docs/USER_GUIDE.md). The upstream project currently documents Node.js 20+. For this role model, use its setup command with --skip-register so Claude and Codex are not independently registered as MCP clients.

Recommended sequence:
1. Install Agent Bridge in a neutral tools directory, not inside the ALTA repository.
2. Configure named workspaces. Initially allow only a disposable test workspace and keep HTTP bound to 127.0.0.1.
3. Run the upstream doctor, tests, build, and HTTP smoke test.
4. Keep Claude Code and Codex CLI as broker-launched workers; do not register them as MCP clients.
5. Connect only the ChatGPT desktop app to the local MCP endpoint using its MCP server settings.
6. Install/update this Supervisor Skill in Claude Code.
7. Run acceptance tests in a disposable workspace before adding real project folders.

See [Agent Bridge Integration](docs/AGENT-BRIDGE-INTEGRATION.md) for the operating contract and acceptance checks.

## Mandatory routing rules

- ChatGPT is the only orchestrator and submits tasks with source_agent = chatgpt.
- ChatGPT explicitly selects claude or codex as the target.
- Claude is the implementation agent. Use workspace_write only for bounded, PO-authorized work in an isolated workspace.
- Codex is always read_only. Never submit a Codex task with workspace_write.
- Only ChatGPT is configured as an MCP client for orchestration. Claude and Codex run as workers launched by Agent Bridge; they do not create follow-up tasks or delegate to one another.
- Start with read_only. Do not assume a task's allowedPaths list is enforced by the broker as a filesystem sandbox.
- The user remains Product Owner; product choices and reserved sensitive approvals are not delegated.

## Important security boundary

Agent Bridge's workspace allowlist limits which configured workspace can be selected. Its workspace_write mode grants write capability within that workspace; it is **not a per-file allowedPaths sandbox**. A path list in a task is an instruction contract, not an independent filesystem boundary.

Use a disposable workspace for initial write-mode acceptance. Keep real projects read-only until an isolated working copy or worktree is prepared and reviewed. Keep ALTA read-only until its existing working-tree state is preserved and a separate safe implementation workspace is established. Keep secrets, tokens, .env files, and private credentials out of task text and context. Do not expose the broker publicly for this local workflow.

## Task and report lifecycle

ChatGPT calls agent_bridge_capabilities before first use, then submits one bounded task using delegate_task with source_agent = chatgpt. It selects Claude for implementation or Codex for independent audit, applies the least-permissive mode, retrieves the result with get_task, evaluates the evidence, and chooses the next assignment.

The queue is asynchronous, but a completed task does **not** itself wake this ChatGPT conversation. The ChatGPT client must retrieve the task result. Do not claim event-driven notification unless a separate, tested notification mechanism exists.

## Former GitHub inbox

The private repository warclock89/claude-codex-inbox is retained as a private fallback/reference only. Do not create duplicate active tasks in both GitHub and Agent Bridge. Agent Bridge is the intended primary task transport.

## Current integration status

This branch contains the combined architecture, updated Supervisor Skill, and an integration/acceptance guide. It does **not** prove that Agent Bridge has been installed on the user's Windows machine or connected to this ChatGPT session. Local setup and live round-trip checks remain pending.

## Install this Skill on Windows

Requirements: Git and Claude Code installed.

~~~powershell
git clone https://github.com/warclock89/claude-codex-supervisor-relay.git
cd claude-codex-supervisor-relay
./scripts/install-skill.ps1
~~~

The installer copies the Skill to the Claude user skills directory. It refuses to overwrite an existing installation; review and deliberately replace the old Skill only after backing it up.

## Safety defaults

- Preserve all pre-existing modified and untracked files.
- Never run automatic Git add, commit, push, fetch, stash, reset, checkout, clean, rebase, or merge.
- No unbounded correction loops or opportunistic refactors.
- Supabase, SQL writes, migrations, secrets, credentials, deployments, production operations, and destructive changes require the specific authorization reserved by the project and PO.
- Never claim a test, audit, installation, or live handoff passed unless it actually ran and its result was observed.

## License

No open-source license has been selected for this repository. Do not assume public availability grants permission to redistribute or modify its contents.
