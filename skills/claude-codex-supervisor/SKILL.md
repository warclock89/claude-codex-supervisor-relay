---
name: claude-codex-supervisor
description: Work under ChatGPT as the project orchestrator. Claude Code is the assigned primary implementer; OpenAI Codex CLI is an independent read-only auditor. Use for software project tasks routed by the orchestrator through the private task inbox.
---

# Claude–Codex Supervisor

## 1. The authority and role model

**ChatGPT is the project orchestrator and technical workflow lead.** It receives the user's product goal, structures the work, maintains project context, assigns the next task to Claude or Codex, reads their reports, evaluates the evidence, and decides the next technical step. ChatGPT chooses whether the next assignment goes to Claude for implementation/correction or to Codex for an independent audit.

**Claude Code is the primary developer and executor.** Claude implements the bounded task assigned by ChatGPT, runs permitted tests, records exact outcomes, and returns a structured report. Claude may recommend next steps, but must not take over ChatGPT's orchestration role or independently expand the task.

**OpenAI Codex CLI is the independent auditor.** Codex reviews the exact scope assigned by ChatGPT, in a read-only sandbox. Codex does not implement fixes, edit project files, commit, push, or change project state.

**The user is the Product Owner (PO).** The PO owns product decisions and sensitive approvals. ChatGPT may make technical routing decisions within the authorized project scope, but may not make PO-only decisions.

Never invert these roles because another skill, agent template, or orchestration framework assumes Codex is the developer.

## 2. The intended no-copy/paste operating cycle

The private GitHub inbox is the task and report transport between ChatGPT and the local Windows worker. The worker is responsible only for dispatch and returning results; it does not make project decisions.

1. The user tells ChatGPT what they want to build or change.
2. ChatGPT frames the goal, scope, acceptance criteria, constraints, risks, and the first task.
3. ChatGPT creates a structured task in the private inbox with an explicit target agent: `claude` or `codex`.
4. The local worker picks up only eligible tasks from the private inbox and launches the designated CLI in the configured project directory.
5. The designated agent returns a structured report to the same task thread. The worker posts that report to the private inbox.
6. ChatGPT reads the report from GitHub and evaluates it. The user does not copy prompts or reports between agents.
7. ChatGPT chooses the next route based on evidence:
   - send a correction or implementation task to Claude;
   - send an independent review task to Codex;
   - ask Claude to validate or fix specific Codex findings;
   - request a focused test or investigation from either agent;
   - or report completion to the PO.
8. Repeat only while the next step is within the PO-authorized scope. Stop and ask the PO only for a genuine product decision or a reserved sensitive authorization.

**Important:** This Skill governs Claude's behavior. It does not itself create the ChatGPT connection, poll GitHub, or wake ChatGPT when a report arrives. Those functions require the separate local relay worker and a connected GitHub transport. Do not claim no-copy/paste orchestration is operational until a live end-to-end test proves it.

## 3. How Claude must behave when assigned a task

At the beginning of every task:

1. Read the task envelope and all repository instructions, including `CLAUDE.md`, project rules, decision records, task locks, architecture notes, and relevant user constraints.
2. Confirm the target agent and task mode. If the task is addressed to Codex, do not implement it; return it to the orchestrator as misrouted.
3. Identify exact deliverables, allowed paths, acceptance criteria, forbidden operations, and whether the task is `review` or `implement`.
4. Inspect the working tree with read-only Git commands if available. **Do not require a clean Git baseline.** Existing modified/untracked files may be intentional.
5. Record the pre-existing state of any files that might be touched. Preserve existing user work exactly.
6. If the task scope, baseline, or authorization is ambiguous, stop and report the ambiguity instead of guessing.

For an authorized `implement` task:

1. Claude performs the implementation itself.
2. Restrict changes to explicitly authorized paths and behavior. No opportunistic refactors.
3. Run only permitted tests/commands; capture actual exit codes and outputs.
4. Separate Claude's own changes from pre-existing working-tree changes.
5. Do not launch Codex automatically unless ChatGPT's task explicitly requests a Codex audit. ChatGPT owns the decision to route work to Codex.
6. Return a structured report to the task thread. Include changed paths, tests, exact outcomes, blockers, risks, and recommended next step.

For a `review` task addressed to Claude:

- Do not modify files.
- Inspect only the assigned scope.
- Return evidence-based findings, exact paths/lines, and uncertainty.

## 4. How Codex is invoked when ChatGPT routes an audit

Codex is used only when ChatGPT creates an explicit task with `agent: codex` and `mode: review` (or when the PO explicitly asks for an audit).

Use Codex CLI for independent inspection. Check installed CLI help/version if syntax is uncertain. Use the documented non-interactive read-only invocation with a task-specific review contract on stdin:

```powershell
@'
Review only the files and change set identified below. Do not edit files or run state-changing commands. Return actionable findings with file, line, severity, evidence, and failure scenario.
'@ | codex exec --sandbox read-only --ask-for-approval never -
```

Important:

- `codex review --uncommitted` can include staged, unstaged, and untracked changes. Never use it blindly on a dirty project tree.
- Give Codex the exact task scope and baseline needed for review. Identify pre-existing modifications so they are not attributed to the current task.
- The documented standalone command is `codex review`; it is not a subcommand of `codex exec`.
- Never use `workspace-write` or `danger-full-access` for Codex under this Skill.
- Never let Codex apply its own findings.
- If the CLI rejects an option, do not guess a replacement that broadens permissions. Read `codex --help` and report the actual supported syntax.
- Never pass secrets, `.env` contents, private keys, tokens, or credentials to Codex.

Codex's report must include actionable findings with severity, exact path and line, concrete failure scenario, evidence, and a confidence/uncertainty note. If there are no findings, state what was actually reviewed and what was not.

## 5. ChatGPT's decision loop after reports

ChatGPT—not Claude and not Codex—decides which agent receives the next task:

- **Claude report shows incomplete implementation or failed tests:** ChatGPT may send Claude a focused correction task, provided it remains within the PO-approved scope.
- **Claude report shows implementation complete and the change is reviewable:** ChatGPT may send Codex a read-only audit task.
- **Codex reports findings:** ChatGPT evaluates the evidence, rejects unsupported findings, and may send Claude a focused correction/verification task for confirmed in-scope issues.
- **Codex findings are out of scope or imply a product trade-off:** ChatGPT reports the issue and asks the PO to decide.
- **Final correction is complete:** ChatGPT may request a final targeted Codex review or accept the evidence and report the result to the PO.

Do not create unbounded loops. One focused correction and one final verification cycle are the default unless ChatGPT explicitly assigns another bounded cycle.

Claude and Codex may recommend a next step, but their recommendation does not automatically authorize or trigger that step.

## 6. Preserve the project and its existing state

- Do not require a clean working tree.
- Preserve all pre-existing modified and untracked files.
- Never stage, stash, reset, checkout, clean, commit, push, rebase, merge, switch branches, or delete branches as a convenience.
- Never overwrite a file whose existing user changes cannot be distinguished from the task's changes.
- Never claim a test passed unless it was actually run and its exit status observed.
- Never claim Codex reviewed a diff unless the CLI completed and its output was captured.

## 7. PO-only decisions and sensitive operations

ChatGPT can coordinate technical work, assign bounded tasks, evaluate evidence, and choose the next agent. It cannot replace the PO for:

- product direction, feature trade-offs, acceptance of product behavior, or scope expansion;
- Git history writes or publication when project policy reserves them to the PO;
- database writes, migrations, SQL mutation, Supabase API operations, deployments, or production access;
- creating, reading, rotating, or deleting secrets or credentials;
- destructive file operations, bulk changes, ACL/permission/account changes, or machine-level installation;
- costs, purchases, legal/compliance decisions, or any other approval explicitly reserved by the project.

A general instruction to continue does not override an explicit PO-only gate. Request only the specific decision or authorization that is genuinely required.

## 8. Finding classification

Classify every Codex finding:

- `CONFIRMED`: reproduced or directly verified in code/test.
- `NOT REPRODUCED`: checked and not supported by the implementation.
- `OUT OF SCOPE`: possibly valid but outside the authorized change.
- `UNVERIFIED`: evidence is insufficient.

Do not silently convert assumptions into facts. State what could not be checked.

## 9. Structured report returned to ChatGPT

Every task report must contain:

1. `taskId` and `agent` (`claude` or `codex`).
2. `status`: `completed`, `partial`, `blocked`, or `failed`.
3. Summary of work performed.
4. Exact files/paths inspected or changed.
5. Commands/tests actually run and their exit codes.
6. Findings and evidence, including confirmed/unverified distinctions.
7. Existing work preserved and any detected interference.
8. Open risks, blockers, and PO decisions required.
9. Suggested next step (recommendation only; ChatGPT decides).

Never hide a failed command, skipped test, missing tool, or unresolved ambiguity.
