# session-budget

Claude Code skill for token-budget-aware planning: splits work into atomic blocks, measures each block's cost against the plan's 5-hour limit, and cuts execution before spilling into extra usage. The system self-installs, self-measures, and self-calibrates.

## What it does

- Installs a statusline that persists every usage snapshot (`~/.claude/usage_snapshot.json`) without depending on any parser, so persistence never fails even if rendering does.
- Inserts a session protocol into the project's `CLAUDE.md`: each work block is tagged `[DESIGN]` or `[MECHANICAL]` and sized `S`/`M`/`L`, with a go/no-go rule before starting each one.
- Tracks the backlog state in `SESSION_STATE.md` and an append-only log in `budget_log.jsonl`.
- Delegates `[MECHANICAL]` blocks to an `implementer` subagent pinned to Sonnet, so the per-block model switch is automatic.
- Self-calibrates: recomputes cost medians per (size, model) from the real log, instead of sticking with the defaults (S=5, M=12, L=25).

## Installation

Copy this directory to `~/.claude/skills/session-budget/` (personal, all projects) or `.claude/skills/session-budget/` (per project, versioned in git).

## Usage

See `references/SPEC.md` — the complete source of truth (preflight, deliverables, acceptance tests, kickoff/resume/report prompts). `SKILL.md` is deliberately minimal: all the logic lives in the spec so it doesn't load extra context when the skill isn't needed.

## Origin

This repo is also the first project where the protocol was applied to itself (bootstrap): this skill was built under the same block-and-budget system it documents.
