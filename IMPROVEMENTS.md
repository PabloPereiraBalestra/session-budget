# IMPROVEMENTS

Backlog of ideas for the session-budget protocol/skill. Different from `SESSION_STATE.md`:
that list tracks blocks already planned within an in-progress session; this list collects
loose improvement or new-feature ideas until they're decided to be brought into a real
block (and from there, potentially, into a bump of `references/SPEC.md`).

Flow: idea enters **Proposed** → discussed with the user → moves to **Accepted**
(candidate for a [DESIGN] or [MECHANICAL] block in a future session) or **Discarded** (with
a reason, so it isn't reproposed without context) → once implemented and reflected in the
spec, moves to **Shipped**, citing the spec version and commit.

## Proposed
<!-- new idea, not yet triaged -->
(empty)

## Accepted
<!-- confirmed by the user, waiting to enter a session backlog -->
(empty)

## Discarded
<!-- idea + reason, so it isn't reopened without new context -->
- **"Fable lane" policy** (delegate [MECHANICAL] to Fable agents when the weekly
  Fable allowance has margin, assuming it's near-free capacity for the 5h pool).
  Discarded 2026-07-06 after the measured experiment B21-B24 (see
  `references/FABLE_FEE_FINDINGS.md`): in the controlled comparison, delegating to
  Fable cost ~4x more five_hour per token than delegating to Sonnet (+11pts/62k tokens
  vs +4pts/90k tokens) — the original observation that motivated the idea probably
  confused the 5h pool with the weekly Fable pool (that one did move only with the
  Fable agent, but by barely +1pt). Reopening condition: a future measurement with
  more samples (same task type on both models, different block sizes) that shows
  the opposite.
- **Usage history (time series, `usage_history.jsonl` from the statusline).**
  Discarded 2026-07-05: the used-vs-elapsed proxy (with `resets_at` + known cycle
  length) covers pacing without touching the statusline or handling throttling and
  file rotation. Explicit reopening condition: if the linear projection proves
  insufficient in practice (very bursty consumption that the projection
  misreads), reopen with that evidence.

## Shipped
<!-- idea + spec version it was incorporated into + commit -->
- **"Fable fee" measurement** — blocks B21-B24 (2026-07-06), commits f97f7f4
  (script + baseline), bf1463d (design), b42b114 (Fable implementation), a3da96b
  (Sonnet control). Result and recommendation in `references/FABLE_FEE_FINDINGS.md`
  and in Discarded above. The "Fable lane" policy that motivated the measurement
  didn't hold up, but the user approved including the `agent_model` field proposed
  in the report → spec v24, commits 75e6c88/8b293d1.
- **Token allocator across active projects** — blocks B22-B24 (2026-07-06),
  deliverable in `~/.claude/portfolio/` (outside the repo, same precedent as the
  repo-trust skill from B7): `DESIGN.md`, `assign.ps1`, `projects.json`, `README.md`,
  `tests/` (31/31 own tests). Did not require a spec bump — it lives outside this
  protocol's schema, it's a portfolio tool that consumes it.
- **Mandatory second-order-rule reporting + Cost calibration as single source of
  truth** — spec v23, commit 756bb05 (B19, 2026-07-05). Proposed by budget-auditor
  after auditing 15e13e1..HEAD: the ≥10 actuals threshold had already been crossed
  without evaluating the 3 conditions, and a parallel recap in SESSION_STATE.md had
  gone out of sync with the canonical section.
- **Elapsed-cycle guard for the wall alert** — spec v22, commit d0fbf32
  (B18, 2026-07-05). ≥25% elapsed-cycle threshold before firing, fixes the
  false positive from B15-B16 dogfooding.
- **Parallelize independent blocks** — spec v21, commit cd82142 (B17,
  2026-07-05). "Parallel lanes (conditioned)" subsection: eligible
  [MECHANICAL] lanes with completed deps + disjoint file scope, gate = sum of the
  batch's estimates + buffer, each line `"parallel":true`. Hard-gated at ≥10 qualifying
  non-null actuals (currently 7 — feature dormant until calibration matures).
- **Schematic reports with emoji** — spec v20, commit d2e87f9 (B16,
  2026-07-05). §5.1 with prescriptive templates (checkpoint, close, resume) and
  ✅⚠️🛑🔄📉📈⏸️ legend, binding from §1.2.
- **Unified allowances monitor** — spec v19, commit 0882c85 (B15, 2026-07-05).
  Merged 4 proposals (ultrareview reminder, expiring-limit alert,
  weekly gate/pacing, burning margin before it expires) into the "Allowance pacing"
  subsection of §1.2 + deliverable §1.7 `~/.claude/allowances.json`. Also included:
  reset-aware no-go (<30 min), `effort` field in the block-line schema, and a fix
  for staleness on writes from another live window of the account.
- **Reset-aware no-go** — spec v19, commit 0882c85 (B15, 2026-07-05).
- **Calibration guardrails** — spec v18, commit c5e5c7f (B14, 2026-07-05). A
  bucket needs ≥3 qualifying actuals to override the lower fallback level;
  actuals=0 always count; parallel/spans_reset are the only valid exclusions
  (no discretionary drops).
