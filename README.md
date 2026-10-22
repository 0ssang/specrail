# specrail

A Claude Code plugin that keeps the AI **on the rails of a spec**.

- **Spec-driven development (AI-DLC)**: requirements → design → tasks → implementation. Each phase needs your approval before the next one starts.
- **Session memory**: after `/clear` or auto-compaction, your handoff note, progress log, and spec status are loaded back in automatically.

> Skill prompts and generated documents are currently written in Korean.

Requires `bash` and `jq` (preinstalled on recent macOS; otherwise `brew install jq`).

## Install

Inside Claude Code:

```text
/plugin marketplace add 0ssang/specrail
/plugin install specrail@specrail
```

When developing locally, use the path to this folder instead of `0ssang/specrail`. Start a new Claude Code session after installing.

## Spec workflow

```text
/spec-requirements build a login feature   # 1. specs/user-login/requirements.md
  → review, then approve
/spec-design                               # 2. specs/user-login/design.md
  → review, then approve
/spec-tasks                                # 3. specs/user-login/tasks.md (checklist)
  → review, then approve
/spec-impl                                 # 4. implement one task → verify → check off → report
  → review, then "continue" (or /spec-impl user-login 전부 to run all tasks)
```

- Every spec document starts with a status line, `> 상태: 초안` (draft). When you approve, Claude changes it to `> 상태: 승인됨 (date)` (approved). A phase skill stops if the previous document is not approved.
- Editing an approved document resets it to draft, and it needs approval again.
- If implementation shows the design is wrong, Claude stops and proposes a change to design.md instead of drifting from the spec.
- If a skill name collides with another plugin, prefix it: `/specrail:spec-design`.

## Session memory

```text
... work ...
/session-save      # save a handoff note when a unit of work is done (creates .claude-memory/ on first run)
/clear             # clear the context → the handoff note is injected again
/session-resume    # restore in more detail
```

Session memory is **opt-in per project**: hooks only read and write when the project has a `.claude-memory/` folder. The first `/session-save` creates it, so no files appear in projects you haven't opted in.

| When | What happens |
|---|---|
| Session start · `/clear` · resume · after compaction | Injects spec status (if `specs/` exists), memory rules, handoff note, recent progress, git summary |
| Before compaction | Snapshots changed files, recent requests, last reply, git status (re-injected after compaction) |
| Every prompt | Suggests saving when token usage passes the threshold |
| File edits | Records changed files per session |
| Session end | Appends one line to the session log |

Files created in your project:

```text
specs/<feature>/       requirements.md, design.md, tasks.md
.claude-memory/
  handoff.md           handoff note
  progress.md          work log
  decisions.md         decision log
  session-log.md       session end log
  snapshots/           compaction snapshots (git-ignored)
  .runtime/            per-session changed files (git-ignored)
  config.json          settings (optional)
```

### Settings (`.claude-memory/config.json`; defaults apply when absent)

| Key | Default | Description |
|---|---|---|
| `context_warn_tokens` | `300000` | Suggest saving once context usage passes this many tokens |
| `handoff_inject_chars` | `4000` | Length of the handoff note injected automatically (bytes) |
| `snapshot_keep` | `20` | Number of compaction snapshots to keep |

## Layout

```text
.claude-plugin/marketplace.json   this repository is the marketplace
plugin/
  .claude-plugin/plugin.json
  hooks/hooks.json                hook registration
  hooks/*.sh                      hook scripts and the mem.sh query tool
  rules/session-memory.md         memory rules printed by the SessionStart hook
  skills/                         spec-* (4), session-save, session-resume
```
