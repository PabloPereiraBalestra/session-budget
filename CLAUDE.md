# session-budget

<!-- session-budget-protocol:start -->
## Session budget protocol

### Budget tracking
- Before starting each work block and after finishing it, read ~/.claude/usage_snapshot.json (Windows: %USERPROFILE%\.claude\usage_snapshot.json) and record rate_limits.five_hour.used_percentage in SESSION_STATE.md (session % start/end per block).
- S/M/L are calibration buckets with default estimates S=5, M=12, L=25 session points. Point estimates may be any integer (8, 15, etc.); the bucket only determines which median applies during self-tuning. Defaults are overridden by measured data per the Self-tuning section.
- Go/no-go rule: if (100 - current used_percentage) < estimated cost of next block + 10 buffer, do NOT start it. Leave the repo stable, update SESSION_STATE.md, and report: "No budget for next block. Session resets at <resets_at converted to local time>." If resets_at is less than 30 minutes away, also say so and recommend waiting for the reset to start on a full window instead of closing the session.
- No block may be estimated above 20 points. L placeholders above the cap may sit in the backlog marked SPLIT, but must be split into sub-blocks ≤ cap before entering any session plan.
- If the snapshot file is missing, stale, or rate_limits is null (happens right after session start or /clear), say so and fall back to manual checkpoints: stop after each block and wait for my go. Staleness check: if the payload includes session_id (present in current builds, see §2 of the session-budget spec, references/SPEC.md in the skill repo), match it against the current session's id; a mismatching id is stale only if the write also predates this session's first prompt — a later write from another live window of this account is fresh (rate_limits are account-wide) but signals parallel activity: treat the snapshot as usable and flag blocks "parallel":true while it persists. Otherwise treat a last-write time predating this session's first prompt as stale. When in doubt, stale.

### Allowance pacing
- The 5h gate is one instance of a general goal: every account allowance (five_hour and seven_day from the snapshot; billing-cycle allowances the snapshot does not expose, like ultrareview free runs, from ~/.claude/allowances.json) should end its cycle near 100% used without work ever hitting a wall.
- At every resume and block checkpoint (never mid-block, never unprompted between them), compute each cycle's elapsed fraction (from its reset time and known cycle length) and project final usage linearly: projected = used% × (cycle length / elapsed time).
- Waste alert: if ≥70% of the cycle has elapsed and projected usage at reset is <60%, say so and propose how to consume the margin before it expires: pull forward cheap [MECHANICAL] blocks, run a budget-auditor audit, spend remaining ultrareview free runs.
- Wall alert (seven_day only; five_hour is already gated per block): if projected usage reaches 100% before the cycle resets, recommend sonnet as main-thread model and defer heavy [DESIGN] work past the reset.
- ~/.claude/allowances.json registers allowances the snapshot does not expose (schema in §1.7 of the session-budget spec, references/SPEC.md in the skill repo). Update `used` when a run is observed. While `used` or `resets` is null, ask the user once per resume to fill them; never guess and never alert from null data.
- Per-model weekly caps are not in the snapshot either; when the user reports one (e.g. "90% of Fable free until 19:00"), treat it as an allowances.json-style cycle for pacing and model-choice decisions.

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
- Checkpoint, session-close and resume reports follow the fixed templates in §5.1 of the session-budget spec (references/SPEC.md in the skill repo): schematic, emoji legend, prose only for what the template can't carry.

### Parallel lanes (conditioned)
- Only once calibration has produced ≥10 non-null actuals across logged blocks (the phase the Self-tuning second-order rules also gate on) — below that threshold, run blocks one at a time regardless of what's eligible below.
- Eligible lanes: pending [MECHANICAL] blocks whose dependencies are already completed AND whose file scope is disjoint from every other eligible lane in the same batch (no two lanes touch the same file). [DESIGN] blocks are never batched — they stay one at a time in the main thread per the existing rule.
- Gate: sum the estimates of every lane in the batch (never the max — the 5h pool is shared even though wall-clock is parallelized) and apply the existing go/no-go rule to that sum + buffer.
- Delegate each lane to its own implementer subagent invocation. The orchestrator reads the snapshot once before and once after the whole batch (not per lane) and logs one block line per lane, each flagged "parallel":true — concurrent consumption from the shared pool must never feed calibration, same as any other parallel account activity.

### Metrics logging
- After completing each block, append one line to budget_log.jsonl (project root, append-only). Capture the real local timestamp before composing the line, never a placeholder. Never edit past lines and never rewrite the file to fix one; if an appended line came out wrong, append a corrective line referencing it instead:
  {"t":"block","ts":"<ISO local>","tag":"<DESIGN|MECHANICAL>","size":"<S|M|L>","model":"<model.display_name from snapshot>","effort":"<effort.level from snapshot, omit if unavailable>","est":<points>,"actual":<end_pct - start_pct>,"start_pct":<n>,"end_pct":<n>,"commit":"<hash>","clean":<true|false>}
  In manual mode (no usable snapshot): model from session context, actual/start_pct/end_pct = null. "effort" records the main thread's effort level at block close; calibration buckets remain (size, model) — the field only accumulates data for a possible future split by effort.
  If a block spans a session reset (resets_at changed between the start and end reads, or end_pct < start_pct), log actual=null and add "spans_reset":true; a cross-reset delta is never a valid actual. This includes blocks paused on an external blocker and resumed in a later window.
  If other account activity ran while the block executed (parallel Claude Code window, claude.ai chat, or Cowork session — known to the orchestrator or reported by the user), add "parallel":true: the 5h pool is account-wide, so the block's measured actual includes that activity's consumption and must not feed calibration.
  If `commit` would be null outside manual mode, that's only valid when the block's deliverable lives entirely outside any git working tree (e.g., an install-if-absent file under `~/.claude/`). In that case the line must also carry a "note" field explaining why, and must never be backfilled with an unrelated block's commit hash as a stand-in.
  If two or more blocks close in the same wrap-up and a distinct real per-block timestamp is unrecoverable, do not let the lines share an identical timestamp silently — mark the affected line(s) "ts_approximate":true.
- Corrections are append-only lines too: {"t":"correction","ref":"<commit or ts of the corrected line>","set":{"<field>":<value>}}. `set` must contain at least one field to change. Self-tuning and reports apply the latest correction referencing a line before using it. Never rewrite or delete the original line. A rationale-only annotation that changes no field is not a correction — use {"t":"note","ref":"<commit or ts of the referenced line>","text":"<explanation>"} instead.
  clean=false if the block later needed a revert or fix commit; record by appending {"t":"fix","ref":"<commit>"}, never by editing.
- On every session close (any reason), append:
  {"t":"session_end","ts":"<ISO local>","end_pct":<n|null>,"cut_reason":"<budget_gate|user_cut|limit_hit|work_done>","blocks_done":<n>,"buffer":<n>,"cap":<n>,"mode":"<auto|manual>"}
  limit_hit = the 5h limit interrupted work mid-block. budget_gate = the go/no-go rule stopped us. work_done = backlog empty.

### Self-tuning
- On every resume, before planning: read the last 30 lines of budget_log.jsonl. Recalibrate each (size, model) estimate as the MEDIAN of its last 5 non-null actuals, excluding lines flagged "parallel":true or "spans_reset":true (they stay in the log for reporting, but never feed calibration). A bucket's median overrides the fallback level below it only once the bucket has ≥3 qualifying actuals; with fewer, fall through. Fallback order: (size, model) → size-only median (same ≥3 rule) → defaults. actual=0 lines are qualifying data like any other (with n≥3 the median absorbs them); the two flags above are the ONLY valid exclusions — never drop a line from calibration by judgment call. Write the result to the Cost calibration section of SESSION_STATE.md. Silent, no announcement needed.
- Second-order rules, only once the log has ≥10 block entries with non-null actuals (before that: calibration phase, first-order only):
  - If any of the last 3 sessions ended in limit_hit: set buffer=15 and cap=15. Announce in one line.
  - If the last 3 sessions all ended in budget_gate with end_pct < 75: set cap=12 to force finer granularity. Announce in one line.
  - If the median absolute estimation error of a (size, model) bucket exceeds 40% over its last 5 blocks: flag it in the resume summary and propose how to re-scope that block size. Do NOT silently redefine what S/M/L mean.
- Buffer and cap changes revert to defaults (10/20) after 5 consecutive clean sessions (no limit_hit, end_pct ≥ 80 on budget_gate cuts).
- Never modify this protocol itself. Structural changes get proposed to the user, with log evidence, and applied only on approval.

### On "cortamos"
- Leave repo stable, update SESSION_STATE.md, append the session_end log line, summarize in 3 lines: what got done, next block, session resets_at (or "manual mode" if no snapshot).
<!-- session-budget-protocol:end -->
