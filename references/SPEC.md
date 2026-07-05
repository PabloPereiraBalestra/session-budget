# Session Budget System — Implementation Spec

**Version: v16 (2026-07-05).** The canonical copy of this file is `references/SPEC.md` in the `session-budget` skill repo. Per-project installs (the CLAUDE.md protocol section, and any local spec copy a project may keep) are derived and get resynced from there (see §0.1 version sync rule). Upgrading the system = editing this file in the skill repo, bumping the version, committing, then resuming affected projects.

Token-budget-aware planning for Claude Code: work is split into atomic blocks, each block's session cost is measured against the plan's 5-hour rate limit, and execution stops cleanly before spilling into extra usage. The system self-installs, self-measures, and self-tunes.

**Portability goal:** this spec must work on the first attempt in any project, on any OS, whether or not the system is already installed, without assuming file names, existing configuration, or auth type. Every assumption is checked in §0; every failure mode degrades to a defined manual fallback, never to improvisation.

---

## 0. Preflight — run before ANY kickoff or resume

### 0.1 System state check

Verify each deliverable of §1 exists:

| Deliverable | Check |
|---|---|
| Statusline script with snapshot persistence | script file exists AND `statusLine` present in `~/.claude/settings.json` |
| `~/.claude/usage_snapshot.json` | file exists (may be stale; freshness is checked in 0.3) |
| "Session budget protocol" section | present in project `CLAUDE.md` between the §1.2 markers AND identical to §1.2 (else: version sync rule below) |
| `SESSION_STATE.md` | exists at project root |
| `budget_log.jsonl` | exists at project root |
| `.claude/agents/implementer.md` | exists with `model: sonnet` frontmatter |
| `~/.claude/agents/budget-auditor.md` | exists with `model: sonnet` frontmatter (user-level, shared across every project) |

If ANY item is missing: the first block of the plan is **B0 [MECHANICAL, M, 12] — bootstrap**: implement every missing §1 deliverable, run the §4 acceptance tests, and show SESSION_STATE.md for approval before committing. The current session runs on manual checkpoints (the snapshot cannot exist or be trusted yet).

**Version sync rule:** if the CLAUDE.md section between the markers differs from §1.2 of this file (the skill repo's `references/SPEC.md`), resync it from here (this file wins) as part of the preflight, no approval needed, and announce it in one line with the spec version. Never edit the CLAUDE.md section directly; changes go to this file first.

### 0.2 Environment check

- **OS**: detect Windows vs macOS/Linux. Determines script language and paths in §1.1. "Home" below means `%USERPROFILE%` on Windows, `$HOME` elsewhere.
- **Auth**: if `ANTHROPIC_API_KEY` is set in the environment, Claude Code bills the API key, not the subscription, and `rate_limits` will never populate. Warn the user and operate in **permanent manual mode** (§3.4) until they unset it or accept it.
- **Existing statusline**: if `settingsjson` already has a `statusLine` entry, do NOT replace it — apply the wrapper rule of §1.1.

### 0.3 Post-bootstrap sequence (first run only)

The statusline loads at Claude Code startup, so the snapshot cannot appear mid-session. After B0 is approved and committed, hand off with exactly this message:

> B0 done. To activate the budget system: (1) close and reopen Claude Code, (2) paste the Resume prompt (§5), (3) after my first reply, I'll confirm whether the snapshot populated. If it did, automatic gating is on; if not, we continue on manual checkpoints and I'll say why.

This means **the first run always includes one manual-mode session**. That is by design, not a failure: the measuring instrument is part of what gets built (bootstrap problem). The spec's job is to make that first session predictable.

---

## 1. Deliverables

All deliverables are **idempotent**: check before create, merge before write, never duplicate, never clobber user data. Re-running the full installation on an already-installed project must be a no-op (§4 test 8).

### 1.1 Statusline script with snapshot persistence

Create in `~/.claude/`: `statusline.ps1` (Windows, PowerShell) or `statusline.sh` (macOS/Linux, bash). Behavior, in order:

1. Read the full stdin into a variable. If empty, exit 0 silently.
2. **Persist the raw stdin verbatim** to `~/.claude/usage_snapshot.json`, overwriting. This step must not depend on any parser (no jq/ConvertFrom-Json needed to write) so persistence works even if rendering fails. On Windows write with `[IO.File]::WriteAllText` (no BOM); `Out-File` adds a BOM and breaks the byte-exact persistence required by §4 test 1.
3. Render one line: `5h: <pct>% | 7d: <pct>% | ctx: <pct>%`. Parse with `ConvertFrom-Json` (Windows) or `jq` if available, else a `python3 -c` one-liner (macOS/Linux). Missing/null fields render as `--`. Never crash; never print anything else to stdout.

**Wrapper rule (pre-existing statusline):** if `statusLine` already exists in settings, generate the script as a transparent wrapper instead: persist stdin (step 2), then pipe the same stdin to the user's original command and print its stdout unchanged. Record the original command in a comment at the top of the wrapper for easy revert. The user's visible statusline must not change.

Wire in `~/.claude/settings.json` (merge into existing JSON, preserve all other keys):

```json
{
  "statusLine": {
    "type": "command",
    "command": "<absolute path invocation>"
  }
}
```

Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/<USER>/.claude/statusline.ps1` (forward slashes, mandatory: when Git Bash is installed, Claude Code routes the statusline command through it and unquoted backslashes are eaten as escape characters, so the command fails with no visible error and the bar never renders; first item in the official statusline troubleshooting, and PowerShell's `-File` accepts forward slashes). macOS/Linux: `bash /home/<user>/.claude/statusline.sh` (or `/Users/...`). Always the absolute resolved path, since `~` is not expanded in this field.

### 1.2 CLAUDE.md protocol section

Insert into the project's `CLAUDE.md` between literal marker comments. If the markers already exist, replace everything between them (this is how the protocol gets upgraded); never append a second copy. If the section header exists **without** markers (pre-v3 install), replace from the header through the end of that section and add the markers.

```markdown
<!-- session-budget-protocol:start -->
## Session budget protocol

### Budget tracking
- Before starting each work block and after finishing it, read ~/.claude/usage_snapshot.json (Windows: %USERPROFILE%\.claude\usage_snapshot.json) and record rate_limits.five_hour.used_percentage in SESSION_STATE.md (session % start/end per block).
- S/M/L are calibration buckets with default estimates S=5, M=12, L=25 session points. Point estimates may be any integer (8, 15, etc.); the bucket only determines which median applies during self-tuning. Defaults are overridden by measured data per the Self-tuning section.
- Go/no-go rule: if (100 - current used_percentage) < estimated cost of next block + 10 buffer, do NOT start it. Leave the repo stable, update SESSION_STATE.md, and report: "No budget for next block. Session resets at <resets_at converted to local time>."
- No block may be estimated above 20 points. L placeholders above the cap may sit in the backlog marked SPLIT, but must be split into sub-blocks ≤ cap before entering any session plan.
- If the snapshot file is missing, stale, or rate_limits is null (happens right after session start or /clear), say so and fall back to manual checkpoints: stop after each block and wait for my go. Staleness check: if the payload includes session_id (present in current builds, see §2 of the session-budget spec, references/SPEC.md in the skill repo), match it against the current session's id; otherwise treat a last-write time predating this session's first prompt as stale. When in doubt, stale.

### Work block protocol
- Blocks are atomic: each one ends in a stable state (compiles, tests pass, clean commit). Never leave work half-done.
- Ordered by dependency. Each block tagged [DESIGN] (architecture decisions, needs my review) or [MECHANICAL] (direct implementation of already-decided work), plus S/M/L.
- One block at a time. After each block: commit, update SESSION_STATE.md, apply go/no-go, stop and wait for my go.
- Never expand a block's scope. Newly discovered work goes into SESSION_STATE.md as a pending block.
- If a block is trending over its estimate, warn me before exceeding it, not after.
- At each checkpoint, read context_window.used_percentage from the snapshot. If ctx ≥ 60 (default, tune with evidence), recommend a context cut before the next block: /clear + the Resume prompt (§5 of the session-budget spec, references/SPEC.md in the skill repo). State is already persisted at every checkpoint, so the cut costs one preflight, while a fat context makes every subsequent turn more expensive against the 5h pool (the full history is resent on each turn). Never /clear mid-block.
- [MECHANICAL] blocks are delegated to the `implementer` subagent (pinned to Sonnet in its frontmatter). The orchestrator reads the snapshot before and after the delegation and logs the block itself. [DESIGN] blocks run in the main thread.
- On each resume, after computing the window plan, recommend the main-thread model and effort for this window: sonnet for admin or MECHANICAL-heavy windows, opus at high effort only when the window contains genuinely hard [DESIGN] blocks. State it in one line; the user switches with /model and /effort.
- If the plan source is ambiguous or the named plan file is absent/outdated, identify candidates from the repo (plan files, recent commits, CLAUDE.md references), state the evidence, and confirm the source with the user before planning. Never plan from a file just because a prompt named it.

### Metrics logging
- After completing each block, append one line to budget_log.jsonl (project root, append-only). Capture the real local timestamp before composing the line, never a placeholder. Never edit past lines and never rewrite the file to fix one; if an appended line came out wrong, append a corrective line referencing it instead:
  {"t":"block","ts":"<ISO local>","tag":"<DESIGN|MECHANICAL>","size":"<S|M|L>","model":"<model.display_name from snapshot>","est":<points>,"actual":<end_pct - start_pct>,"start_pct":<n>,"end_pct":<n>,"commit":"<hash>","clean":<true|false>}
  In manual mode (no usable snapshot): model from session context, actual/start_pct/end_pct = null.
  If a block spans a session reset (resets_at changed between the start and end reads, or end_pct < start_pct), log actual=null and add "spans_reset":true; a cross-reset delta is never a valid actual. This includes blocks paused on an external blocker and resumed in a later window.
  If other account activity ran while the block executed (parallel Claude Code window, claude.ai chat, or Cowork session — known to the orchestrator or reported by the user), add "parallel":true: the 5h pool is account-wide, so the block's measured actual includes that activity's consumption and must not feed calibration.
- Corrections are append-only lines too: {"t":"correction","ref":"<commit or ts of the corrected line>","set":{"<field>":<value>}}. Self-tuning and reports apply the latest correction referencing a line before using it. Never rewrite or delete the original line.
  clean=false if the block later needed a revert or fix commit; record by appending {"t":"fix","ref":"<commit>"}, never by editing.
- On every session close (any reason), append:
  {"t":"session_end","ts":"<ISO local>","end_pct":<n|null>,"cut_reason":"<budget_gate|user_cut|limit_hit|work_done>","blocks_done":<n>,"buffer":<n>,"cap":<n>,"mode":"<auto|manual>"}
  limit_hit = the 5h limit interrupted work mid-block. budget_gate = the go/no-go rule stopped us. work_done = backlog empty.

### Self-tuning
- On every resume, before planning: read the last 30 lines of budget_log.jsonl. Recalibrate each (size, model) estimate as the MEDIAN of its last 5 non-null actuals, excluding lines flagged "parallel":true or "spans_reset":true (they stay in the log for reporting, but never feed calibration). Fallback order: (size, model) → size-only median → defaults. Write the result to the Cost calibration section of SESSION_STATE.md. Silent, no announcement needed.
- Second-order rules, only once the log has ≥10 block entries with non-null actuals (before that: calibration phase, first-order only):
  - If any of the last 3 sessions ended in limit_hit: set buffer=15 and cap=15. Announce in one line.
  - If the last 3 sessions all ended in budget_gate with end_pct < 75: set cap=12 to force finer granularity. Announce in one line.
  - If the median absolute estimation error of a (size, model) bucket exceeds 40% over its last 5 blocks: flag it in the resume summary and propose how to re-scope that block size. Do NOT silently redefine what S/M/L mean.
- Buffer and cap changes revert to defaults (10/20) after 5 consecutive clean sessions (no limit_hit, end_pct ≥ 80 on budget_gate cuts).
- Never modify this protocol itself. Structural changes get proposed to the user, with log evidence, and applied only on approval.

### On "cortamos"
- Leave repo stable, update SESSION_STATE.md, append the session_end log line, summarize in 3 lines: what got done, next block, session resets_at (or "manual mode" if no snapshot).
<!-- session-budget-protocol:end -->
```

### 1.3 SESSION_STATE.md template

Create at project root only if absent (never overwrite an existing one with data):

```markdown
# SESSION_STATE

Backlog source: <file §section> (confirmed by user on <date>)

## Pending blocks
<!-- ordered by dependency: [TAG] size est_points — description | dep -->

## In progress
(none)

## Completed
<!-- [TAG] size — description | commit <hash> | session % start→end | actual points -->

## Cost calibration
<!-- medians by (size, model) from budget_log.jsonl, e.g. S/Sonnet=4, M/Sonnet=9, M/Fable=14 -->
<!-- defaults when no data: S=5 M=12 L=25 | current buffer=10 cap=20 -->

## Minimal context to resume
(max 10 lines)
```

### 1.4 budget_log.jsonl

Create empty at project root only if absent. Append-only; schemas in §1.2 Metrics logging. One JSON object per line, no arrays, no editing of past lines. Single source of truth for self-tuning and the budget report.

### 1.5 Implementer subagent

Create `.claude/agents/implementer.md` only if absent:

```markdown
---
name: implementer
description: Executes [MECHANICAL] work blocks exactly as scoped by the orchestrator. Direct implementation of already-decided work only.
model: sonnet
---
You execute exactly one work block per invocation, as scoped in the delegation prompt.
- Implement only what the block defines. No scope expansion, no opportunistic refactors.
- End in a stable state: code compiles, tests pass, one clean commit named after the block.
- If the block cannot be completed as scoped, stop and report why. Do not improvise around it.
- Report back: files touched, commit hash, test results, and anything discovered that should become a new pending block.
```

The `model: sonnet` field pins this agent regardless of the main thread's model — this is what makes per-block model switching automatic. Budget measurement and logging stay in the orchestrator, never in this agent.

### 1.6 Budget-auditor subagent (user-level)

Create `~/.claude/agents/budget-auditor.md` only if absent (personal scope, shared across every project — per Claude Code's official subagent docs, user subagents live in `~/.claude/agents/`; project subagents in `.claude/agents/` take precedence on a name collision). Deliberately named `budget-auditor`, not a generic name, to avoid colliding with another tool's subagent at the same personal scope.

```markdown
---
name: budget-auditor
description: Audits a project's actual compliance with the session-budget protocol — logging schema, calibration exclusions, gating, and the spec's §6 success criteria — using only that project's on-disk artifacts (budget_log.jsonl, SESSION_STATE.md, git commits). Invoke on demand, never automatically on session_end. Must run blind to whoever executed the audited blocks — the invoking prompt must not describe what happened, only point at the files and commit range to read.
model: sonnet
---
You audit the session-budget protocol for one project, using exactly three sources: the full `budget_log.jsonl`, `SESSION_STATE.md`, and the git commits the audited session references. Nothing else — no conversation history, no other files, no assumption about what "probably" happened during the session. A SESSION_STATE.md claim with no backing commit or log line is unverified, not true.

For every check, quote the exact log line or commit as evidence:
- Every `block`/`session_end`/`correction`/`fix` line has the required fields and valid enum values (CLAUDE.md's Metrics logging section is the schema).
- Self-tuning excluded `parallel:true` and `spans_reset:true` lines from calibration medians.
- Go/no-go was actually respected: no block's `start_pct` implies remaining budget was below (estimate + buffer) at the time it started.
- §6 success criteria, computed directly from the log: zero `limit_hit`, mean `end_pct` ≥80 on `budget_gate` cuts, ≤30% median estimation error per (size, model) bucket, ≥90% `clean=true`.

Report as a short table: check, pass/fail, evidence. If the spec itself should change based on what you find, propose the change as text with a suggested version bump — never edit CLAUDE.md, budget_log.jsonl, or SESSION_STATE.md yourself.
```

Trigger: on demand only, integrated into the §5 Budget report prompt. No auto-trigger on `session_end` (the worst moment to spend pool; after a `limit_hit` the opportunity doesn't even exist).

---

## 2. stdin JSON reference

The statusline command receives JSON on stdin on every render. Relevant shape (verify current schema at https://code.claude.com/docs/en/statusline before implementing):

```json
{
  "session_id": "...",
  "model": { "id": "...", "display_name": "..." },
  "context_window": { "used_percentage": 8 },
  "rate_limits": {
    "five_hour": { "used_percentage": 23.5, "resets_at": 1738425600 },
    "seven_day": { "used_percentage": 18, "resets_at": 1743120000 }
  }
}
```

`resets_at` is a Unix epoch. `session_id` identifies the Claude Code session that produced the render; matching it against the current session's id is the sharpest freshness check. `seven_day` is the overall weekly limit; per-model weekly breakdowns are NOT in this payload. `rate_limits` populates only for Claude.ai subscription auth (Pro/Max), never for API-key auth.

---

## 3. Known constraints (must be handled)

1. **Restart requirement**: the statusline activates at Claude Code startup. Installing it mid-session has no effect until restart — hence §0.3.
2. **rate_limits gaps**: absent until the first API response of a session, and again right after `/clear` until the next response. The protocol's fallback rule covers this.
3. **Every stdin field is optional.** Parse defensively; persistence (§1.1 step 2) must not depend on parsing.
4. **API-key auth = permanent manual mode**: install everything anyway (blocks, log, subagent, atomicity all still work), but skip snapshot reads, log actuals as null, and replace go/no-go with user checkpoints. Self-tuning stays dormant until non-null actuals exist.
5. **Pre-existing statusline**: never replace or degrade it; wrapper rule of §1.1.
6. **Shared pool**: subagent consumption counts against the same 5h limit, so orchestrator-level snapshot deltas measure delegated blocks correctly.
7. The snapshot updates on each render (after each assistant response). Mid-block reads reflect the previous turn — sufficient for per-block gating.
8. **Account-wide pool**: the 5h and 7d limits belong to the account, shared by every parallel Claude Code window, claude.ai chat, and Cowork session. The gate always sees the truth because it reads the live snapshot right before each block, but a block's measured actual includes whatever parallel sessions consumed while it ran. Medians absorb occasional background noise; run the first calibration blocks without parallel sessions so the baseline reflects the block's own cost, then work normally.

**Troubleshooting — snapshot absent after restart:** the user settles the first branch by looking at the terminal: does the status line render at the bottom? If it does NOT render, the script isn't being invoked. On Windows the most common cause is backslashes in `statusLine.command` eaten by Git Bash routing (fix: forward slashes, §1.1); otherwise check for another `statusLine` entry in a higher-precedence settings file (project `.claude/settings.json` or `settings.local.json`), then run the exact command from settings in a plain terminal with mock stdin. If it DOES render but the file never appears, the write is failing silently: temporarily remove the script's error suppression and redirect errors to a log file to capture the cause. Stay in manual mode (actuals = null) until the snapshot writes in live runtime.

---

## 4. Acceptance tests

Run all, report results:

1. Pipe mock JSON with full `rate_limits` into the script → correct percentages rendered AND `usage_snapshot.json` contains the exact input bytes.
2. Pipe mock JSON **without** `rate_limits` → renders `--`, exits 0, snapshot still written.
3. Pipe empty stdin → exits cleanly, no crash, snapshot untouched.
4. `settings.json` is valid JSON after the merge, every pre-existing key survived, and on Windows `statusLine.command` uses forward slashes in the script path.
5. If a statusline pre-existed: with the wrapper installed, mock stdin produces the original statusline's output unchanged AND the snapshot is written.
6. Append one sample block line and one session_end line to budget_log.jsonl, verify both parse as JSON, remove the samples.
7. `.claude/agents/implementer.md` has valid frontmatter including `model: sonnet`.
8. **Idempotency**: run the full installation a second time → zero diffs (no duplicated CLAUDE.md section, settings unchanged, state/log files untouched).
9. After restart, the live statusline renders and the snapshot's timestamp updates after a real assistant response.
10. `~/.claude/agents/budget-auditor.md` has valid frontmatter including `model: sonnet` and `name: budget-auditor`, and re-running the install a second time produces zero diff (install-if-absent).

**Mandatory cleanup after tests 1-8:** delete `~/.claude/usage_snapshot.json`. The tests fill it with mock data; if it survives, the first post-restart resume can mistake mock percentages for a live budget. It regenerates on the first live render (test 9).

---

## 5. Operating prompts

Kickoff (first session in a project, or whenever re-planning from scratch):

```
Arrancamos con el protocolo "Session budget protocol".

0. Preflight (§0 del spec): verificá estado del sistema, entorno y auth. Si falta algún deliverable, B0 es el primer bloque y esta sesión corre por checkpoints manuales.
1. Identificá la fuente del backlog: buscá archivos de plan en el repo, commits recientes y referencias en CLAUDE.md. Decime qué encontraste y confirmá conmigo cuál es la fuente antes de planificar. No asumas un nombre de archivo.
2. Armá la lista de pendientes reales (lo planificado menos lo ya implementado) y reorganizala en bloques según el protocolo: atómicos, por dependencia, [DESIGN]/[MECHANICAL], S/M/L, ninguno arriba del cap.
3. Si hay snapshot utilizable, calculá cuántos bloques entran en esta ventana con el buffer vigente. Si no, decilo y marcá la sesión como manual.
4. Completá SESSION_STATE.md.
5. Mostrame el plan con el corte propuesto y esperá mi OK antes de ejecutar nada.
```

Resume (every new window, after `/clear`):

```
Retomamos según protocolo. Corré el preflight (§0), leé SESSION_STATE.md y el snapshot. Confirmame en 3 líneas: modo (auto o manual y por qué), próximo bloque con costo estimado, y cuántos bloques entran en esta ventana. Con mi OK, ejecutá.
```

Budget report (weekly, or whenever the system feels off):

```
Reporte de presupuesto: leé budget_log.jsonl completo y mostrame en una tabla corta: cortes por tipo (limit_hit / budget_gate / user_cut / work_done), end_pct promedio en cortes por budget_gate, error mediano de estimación por (tamaño, modelo) con su dirección (sobre o subestimación), calibración vigente vs defaults, bloques con clean=false, y sesiones en modo manual. Contrastá contra los criterios de éxito del spec y si alguno no se cumple, proponé el ajuste con la evidencia del log. Si además querés una auditoría formal e independiente, pedime que invoque al subagente budget-auditor sobre este mismo log y SESSION_STATE.md.
```

---

## 6. Success criteria

Evaluated over any rolling window of 5 sessions, excluding the calibration phase (first 10 logged blocks with non-null actuals):

1. Zero `limit_hit` sessions. Primary KPI: no work interrupted by the 5h wall, nothing spilled toward extra usage.
2. Mean `end_pct` ≥ 80 on sessions cut by `budget_gate`. Below that, the system leaves too much window unused. `work_done` cuts excluded.
3. Median absolute estimation error ≤ 30% per (size, model) bucket.
4. ≥ 90% of blocks with `clean=true`.
5. **First-run criterion** (for sharing this as a skill): on a fresh project, B0 completes with all §4 tests green, the handoff message of §0.3 is delivered verbatim, and the first post-restart resume correctly reports auto or manual mode. No improvisation outside the spec.

Interpretation: estimation variance never goes to zero (an unexpected bug can blow any estimate), so the target is zero limit_hits with high window utilization, not perfect predictions. Criteria 1 and 2 are in tension by design; the buffer is the dial between them, and self-tuning moves it with evidence.

---

## 7. Scope

Implement only the deliverables §1 defines (§1.1–§1.6), so this list never drifts from §1 when a deliverable is added. Do not refactor unrelated config, do not add hooks, monitors, or extra tooling. When done: list files created/modified, acceptance test results, and any deviation from spec with its reason.

---

## 8. Packaging as a skill (future, after 2-3 validated sessions)

Target structure, installable at `~/.claude/skills/` (personal, all projects) or `.claude/skills/` (project, shared via git):

```
session-budget/
├── SKILL.md
└── references/
    └── SPEC.md        ← this document, unchanged
```

Draft SKILL.md frontmatter (description in third person per official guidance; the description alone decides when Claude loads it):

```yaml
---
name: session-budget
description: This skill should be used when the user wants token-budget-aware planning in Claude Code - splitting a backlog into atomic blocks gated against the 5-hour plan limit, self-installing the measurement system, and self-tuning estimates from logged data. Trigger on "presupuesto de sesión", "session budget", "planificar por bloques", "no pasarme del límite", or requests to work within plan limits without spilling into extra usage.
---
Run the preflight in references/SPEC.md §0, then follow the spec. Keep this body short; the spec is the source of truth.
```

Body stays minimal: skill bodies persist in context once loaded, so all detail lives in the referenced spec (progressive disclosure).
