# Agent Bridge Integration

**Purpose:** combine this Supervisor Skill's governance model with Agent Bridge's MCP broker and local CLI workers.

This guide records the intended integration. It does not claim the software has been installed or tested on the user's Windows machine.

## 1. Components and ownership

- Supervisor Skill: role hierarchy, task-routing policy, evidence standards, and project safeguards.
- Agent Bridge (upstream): MCP server, task queue, Claude/Codex CLI adapters, status retrieval, and cancellation.
- ChatGPT desktop app: MCP client and sole orchestration authority.
- Claude Code: primary implementation worker.
- Codex CLI: independent read-only auditor.
- User: Product Owner.

Agent Bridge remains a separate upstream project. Do not copy its source code into this repository or imply that this repository maintains it.

Upstream references:
- https://github.com/jcharveyjr/claude-chatgpt-agent-bridge
- https://github.com/jcharveyjr/claude-chatgpt-agent-bridge/blob/main/docs/USER_GUIDE.md
- https://github.com/jcharveyjr/claude-chatgpt-agent-bridge/blob/main/docs/SECURITY.md
- https://github.com/jcharveyjr/claude-chatgpt-agent-bridge/blob/main/docs/VALIDATION.md

## 2. Local topology

For the intended Windows desktop workflow, one local Agent Bridge HTTP broker is exposed to ChatGPT desktop as the sole MCP client:

~~~text
ChatGPT desktop MCP client -------- http://127.0.0.1:8787/mcp
                                             |
                                             v
                                      Agent Bridge
                                      local queue
                                      /         \
                                     v           v
                               claude -p    codex exec
~~~

Do not start multiple broker instances against the same JSON task store. Keep the server bound to loopback (127.0.0.1). Do not expose the broker to the public internet for this setup. ChatGPT desktop is the sole MCP client; Agent Bridge launches Claude and Codex as worker subprocesses.

The upstream guide documents that ChatGPT desktop, Codex CLI, and the IDE extension can share Codex-host MCP configuration. For this governance model, do not register the broker in Claude Code or Codex CLI: their subprocesses are workers, not orchestrators. Configure only ChatGPT desktop as an MCP client. Exact tool exposure must be verified after configuration; a healthy local HTTP endpoint alone does not prove ChatGPT can invoke the tools.

## 3. Installation sequence

This is the documented upstream setup sequence; it has not been run by this repository's automation.

1. Install Node.js 20 or newer. Ensure Git, Claude Code, and Codex CLI are installed and authenticated locally.
2. Clone Agent Bridge into a dedicated tools directory, not into the ALTA repository.
3. From the Agent Bridge root, run the setup script with CLI MCP registration disabled. Claude and Codex are workers launched by the broker; they are not task-submitting MCP clients in this governance model:

~~~powershell
node scripts/setup-local.mjs --skip-register
~~~

4. Inspect bridge.config.json. It is local runtime configuration and must remain untracked.
5. Keep http.host set to 127.0.0.1.
6. Configure named workspaces deliberately. Start with a disposable test folder only; do not add ALTA as a write-enabled workspace.
7. Run the checks documented upstream:

~~~powershell
npm run doctor
npm run typecheck
npm test
npm run build
npm run smoke:http
~~~

8. Start one broker using the upstream documented command, then check http://127.0.0.1:8787/health.
9. Do not register the broker as an MCP server in Claude Code or Codex CLI. Agent Bridge launches those CLIs as worker processes; only ChatGPT should submit tasks.
10. In ChatGPT desktop, open Settings → MCP servers, add a server using Streamable HTTP and endpoint http://127.0.0.1:8787/mcp, save, and restart the app if prompted.
11. In a new ChatGPT desktop session, verify that Agent Bridge tools are actually exposed to the assistant. The local health check is not sufficient evidence.

Upstream setup details can change; consult the linked User Guide before running commands.

## 4. Orchestration contract

Before the first assignment in a ChatGPT session, call agent_bridge_capabilities.

For every task initiated by ChatGPT, use:
- source_agent = chatgpt;
- target_agent = claude or codex;
- a named configured workspace;
- one bounded task and observable success criteria.

Permission mode:
- read_only for all audits, investigations, diagnostics, and all Codex tasks.
- workspace_write only for a bounded Claude implementation task whose scope has PO authorization and whose workspace is safe for writes.

Claude and Codex are worker processes, not MCP clients. They return results only and do not create the next assignment. Do not invoke the upstream generic peer-delegation skill from a worker task; the Supervisor Skill's role hierarchy takes precedence. ChatGPT retrieves the result with get_task(task_id), evaluates the evidence, and chooses the next route.

A separate chat is not automatically awakened when a task finishes. The active ChatGPT client must retrieve the result. Do not describe the integration as event-driven without a separately implemented and tested notification channel.

## 5. Critical permission limitation

The Agent Bridge MCP schema accepts a workspace alias, not a per-task enforced allowed-path list. The broker checks that the selected workspace exists and is accessible. Its workspace_write mode changes the worker sandbox mode for the selected workspace. The upstream broker also accepts workspace_write independently of target_agent; it does not enforce our policy that Codex must always be read_only. This is an important limitation: our Codex read-only rule is enforced by the ChatGPT orchestration instructions and by not registering the broker as a tool for workers, not by a server-side target-agent restriction. The acceptance test must verify that Codex cannot write in read_only mode.

An allowedPaths list included in task text or context is therefore an instruction to the agent, **not a broker-enforced path boundary**. Do not treat it as equivalent to an operating-system sandbox.

Required precautions:
- perform initial write tests in a disposable workspace;
- keep Codex read_only at all times;
- prefer read-only access for real projects until a safe implementation workspace is isolated;
- if write access is needed, use a dedicated worktree or copy whose contents and boundaries have been checked;
- do not give write access to an entire project folder just because a single file is in scope.

**ALTA:** keep it read-only. Its known pre-existing working-tree modifications must not be exposed to an unverified write-enabled worker. First establish a separate isolated implementation workspace; do not modify or clean the live ALTA working tree as part of installing this bridge.

## 6. Security and data handling

Follow the upstream Security guide:
- never place provider cookies, browser session tokens, API keys, or credentials in prompts, context, config files committed to Git, or issue text;
- keep bridge.config.json, .env, .agent-bridge/, and logs out of version control;
- keep HTTP on loopback;
- do not deploy a public broker or configure OAuth without a separate security and deployment review;
- assume task prompts and results may contain sensitive project information;
- use least-privilege local folder permissions.

The upstream repository documents bearer-token and OAuth/JWT modes for protected remote use, but this local workflow should not require a public deployment.

## 7. Acceptance tests

Do not add any real project to a write-enabled workspace until applicable checks below pass.

### A. Broker checks
- npm run doctor succeeds.
- npm run typecheck succeeds.
- npm test succeeds.
- npm run build succeeds.
- npm run smoke:http succeeds.
- /health reports the expected local service.
- The broker process is bound only to 127.0.0.1.

### B. MCP client checks
- Claude Code lists Agent Bridge as connected.
- Codex CLI lists Agent Bridge as connected.
- ChatGPT desktop displays Agent Bridge tools in an active session.
- agent_bridge_capabilities returns both configured worker records and the expected disposable workspace alias.

### C. Real handoffs in a throwaway workspace
1. ChatGPT submits a read-only task to Codex. Verify it completes and makes no file changes.
2. ChatGPT submits a bounded workspace-write task to Claude that creates a harmless test file in the disposable folder. Verify the exact file and no other changes.
3. ChatGPT retrieves both task IDs using get_task.
4. Confirm neither worker initiated an unrequested follow-up delegation.
5. Confirm timeout/cancellation and restart behavior using upstream tests or controlled test tasks.

A task is validated only when its actual status, result, and workspace diff have been observed. Do not infer success from command availability or a healthy broker.

### D. Real-project onboarding
- Add each real project as a named workspace only after review.
- Initially configure real projects for read-only operation.
- For Claude write operations, use a separate isolated worktree/copy with least-privilege access.
- Keep production, database, migration, credentials, deployment, destructive, and other PO-reserved operations separately gated.

## 8. Former GitHub inbox

The private repository warclock89/claude-codex-inbox remains a private fallback/reference. It is no longer the intended primary transport when Agent Bridge is operating.

Do not mirror every Agent Bridge task into GitHub. Two live queues would create duplicate execution, ambiguous status, and competing sources of truth. Use the GitHub inbox only for a deliberate fallback or archival workflow, and never include secrets there.

## 9. Verified facts vs pending checks

Verified from upstream source/documentation during this integration review:
- Agent Bridge exposes agent_bridge_capabilities, delegate_task, get_task, list_tasks, and cancel_task.
- The API permits source_agent = chatgpt and targets claude or codex.
- The broker stores tasks asynchronously and runs the configured local CLI adapter.
- The broker supports read_only and workspace_write modes and named workspace aliases.
- The upstream README and validation guide report automated tests and live CLI handoff tests. Those are maintainer-reported results, not independently rerun by this repository.

Not yet verified for this user environment:
- Agent Bridge installed on the Windows machine.
- Local Node/CLI prerequisites and provider authentication.
- The actual local broker's health and sandbox behavior.
- ChatGPT desktop can see and invoke the configured MCP tools.
- ChatGPT-to-Claude and ChatGPT-to-Codex live tasks complete in this environment.
- A real-project workspace is safely isolated for writes.

Do not upgrade any pending item to verified until the check is actually performed.
