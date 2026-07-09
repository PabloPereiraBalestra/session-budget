# Fable-fee experiment findings (B21-B24)

B25 report. Raw data in `fable_fee_log.jsonl` (repo root, 5 readings:
`baseline`, `pre_b23`, `post_b23`, `pre_b24`, `post_b24`).

## Motivation

`IMPROVEMENTS.md` recorded an informal observation: "two Fable agents (~200k
combined tokens) moved the Sonnet 5h pool only 1 point (62%→63%)". If that
were representative, delegating [MECHANICAL] blocks to Fable agents when the weekly
Fable allowance has margin would be near-free capacity for the 5h window — hence
the idea of a "Fable lane" policy in the protocol.

This experiment instrumented a controlled comparison: the same portfolio
allocator (designed in B22), implemented by a Fable agent (B23) and then
tested/documented by a Sonnet agent as control (B24), measuring the 3
relevant meters (account five_hour, seven_day all-models, weekly Fable)
before and after each delegation.

## Data

| Block | Subagent model | subagent_tokens | tool_uses | five_hour Δ | seven_day (all-models) Δ | Weekly Fable Δ |
|---|---|---|---|---|---|---|
| B23 | Fable 5 | 62,308 | 14 | **+11** (28→39) | +1 (24→25) | +1 (23→24) |
| B24 | Sonnet 5 | 90,673 | 37 | **+4** (39→43) | +1 (25→26) | +0 (24→24) |

five_hour rate per token:
- B23 (Fable): 11 / 62,308 ≈ **1.77 points per 10k tokens**
- B24 (Sonnet): 4 / 90,673 ≈ **0.44 points per 10k tokens**

B23 cost ~4x more five_hour per token than B24, despite B24 doing more real
work (more tokens, more than double the tool calls).

## Interpretation

**The original hypothesis is NOT confirmed — the result points in the opposite
direction.** In this comparison:

1. The five_hour pool (the one that gates this protocol) moved **more**, not less,
   when the work was delegated to Fable — both in absolute terms (+11 vs +4)
   and normalized per token (~4x).
2. Weekly Fable did move exclusively with the Fable agent (+1 vs +0 for the
   Sonnet control) — that confirms that specific meter is tied to the model,
   as expected. But the amount is small (1 point) even for a
   substantial task — consistent with the original "near-free" observation,
   **if that observation referred to the weekly Fable pool and not the 5h
   one**. That's the simplest explanation for the apparent contrast: the
   original note probably confused which meter had moved little.
3. Practical conclusion: delegating [MECHANICAL] work to a Fable agent does not free up
   5h-pool margin — in this measurement, it consumes it faster than delegating
   to Sonnet. The "Fable lane" policy as originally proposed (exploiting weekly
   Fable margin as near-free capacity for the 5h window) **has no support in
   this data**.

## Limitations (n=1 per model, read with caution on magnitude, not direction)

- A single data point per model — this project's own calibration already
  shows median estimation error of 40-60%+ in buckets with little data
  (see `SESSION_STATE.md` → Cost calibration). The exact magnitude (4x) may not
  repeat, but the direction (Fable isn't cheaper on five_hour) is a large
  difference, not a technical tie.
- B23 and B24 are different tasks (implementation vs. tests/docs) and different
  sizes (M vs S) — part of the difference could be due to the shape of the task,
  not just the model. Task type was not controlled for.
- Parallel contamination from another window of the account during the
  interval can't be fully ruled out — a `usage_snapshot.json` write from
  another session (`initium` project) was detected in this session's preflight,
  before the experiment started. The `session_id` checks at the endpoints of
  each measurement (pre/post) showed no such contamination during B23/B24
  specifically, but those are just snapshots, not continuous coverage of the
  interval.
- Both subagents inherited the session's effort (auto) with no explicit override —
  effort level was not controlled for separately from the model.

## Recommendation

- **Do not** adopt the "Fable lane" automatic-delegation policy as originally
  proposed in `IMPROVEMENTS.md`. Move that idea from "Accepted" to "Discarded" with
  this evidence, leaving an explicit reopening condition: if a future measurement
  with more samples (different block sizes, same task type on both
  models) shows the opposite, reopen it.
- The `agent_model` field in the block-line schema (used ad-hoc in this
  session for B23/B24, see notes in `budget_log.jsonl`) did prove useful for
  this type of measurement and is independent of whether the "Fable lane" policy
  is adopted or not — worth proposing as a minor spec bump (records which
  model executed the delegated work, without implying any decision policy). Text
  proposed for user approval, not committed yet (hard protocol rule:
  structural changes only with explicit approval).
- The portfolio allocator (B22-B24) remains valid and useful regardless
  of this result — its model recommendation already falls back to "sonnet"
  for MECHANICAL blocks with no fresh weekly Fable margin, which, in light of
  this finding, is probably the correct default behavior anyway.
