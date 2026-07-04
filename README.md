# session-budget

Skill de Claude Code para planificación consciente del presupuesto de tokens: divide el trabajo en bloques atómicos, mide el costo de cada bloque contra el límite de 5 horas del plan, y corta la ejecución antes de derramar hacia uso extra. El sistema se auto-instala, se auto-mide y se auto-calibra.

## Qué hace

- Instala un statusline que persiste cada snapshot de uso (`~/.claude/usage_snapshot.json`) sin depender de ningún parser, así la persistencia nunca falla aunque el render falle.
- Inserta un protocolo de sesión en el `CLAUDE.md` del proyecto: cada bloque de trabajo se etiqueta `[DESIGN]` o `[MECHANICAL]` y de tamaño `S`/`M`/`L`, con una regla de go/no-go antes de arrancar cada uno.
- Lleva el estado del backlog en `SESSION_STATE.md` y un log append-only en `budget_log.jsonl`.
- Delega los bloques `[MECHANICAL]` a un subagente `implementer` fijado en Sonnet, para que el cambio de modelo por bloque sea automático.
- Se auto-calibra: recalcula las medianas de costo por (tamaño, modelo) a partir del log real, en vez de quedarse con los defaults (S=5, M=12, L=25).

## Instalación

Copiar este directorio a `~/.claude/skills/session-budget/` (personal, todos los proyectos) o `.claude/skills/session-budget/` (por proyecto, versionado en git).

## Uso

Ver `references/SPEC.md` — es la fuente de verdad completa (preflight, deliverables, tests de aceptación, prompts de arranque/resume/reporte). El `SKILL.md` es deliberadamente mínimo: toda la lógica vive en la spec para no cargar contexto de más cuando el skill no hace falta.

## Origen

Este repo es también el primer proyecto donde el propio protocolo se aplicó a sí mismo (bootstrap): la creación de este skill se hizo bajo el mismo sistema de bloques y presupuesto que documenta.
