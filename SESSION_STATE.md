# SESSION_STATE

Backlog source: bloques acordados en esta conversación (bootstrap del repo session-budget + aplicación de repo-trust), confirmado por el usuario el 2026-07-04.

## Pending blocks
<!-- ordered by dependency: [TAG] size est_points — description | dep -->
- [DESIGN] S 5 — B4a: preflight §0 de REPO_TRUST_SPEC (references/SPEC.md del repo repo-trust) sobre este repo, más tabla §0.3 resuelta contra fuentes oficiales. Corre en el hilo principal, requiere 2 confirmaciones del usuario (ecosistema y tabla resuelta). | dep: B3
- [MECHANICAL] M 12 — B4b: escritura de los deliverables §1 del trust spec (security.yml, scorecard.yml, badges README, dependabot.yml, SECURITY.md) + tests §4 locales (1-7). Delegado al subagente implementer. | dep: B4a
- [MECHANICAL] S 5 — B5: push, tests §4 post-push (8: Security tab con findings; 9: Scorecard publica y badge responde 200). Delegado a implementer. | dep: B4b
- [MECHANICAL] S 5 — B6: release de prueba v0.1.0, verificar test §4-10 (SBOM adjunto, parsea como CycloneDX JSON). Delegado a implementer. | dep: B5
- [MECHANICAL] S 5 — B7: empaquetar repo-trust como skill en ~/.claude/skills/repo-trust (SKILL.md + references/SPEC.md). No commitea en este repo, escribe fuera. Test de diff byte a byte contra C:\Users\pablo\OneDrive\Documentos\GitHub\repo-trust\references\SPEC.md (NO contra Downloads — Downloads dejó de ser fuente para REPO_TRUST_SPEC también). Delegado a implementer. | dep: B6
- [DESIGN] S 5 — B8: redactar el contrato del subagente `budget-auditor`. Restricciones:
  a. Nombre `budget-auditor` (no "auditor" pelado — colisiona en scope personal cuando otro instale el skill). Verificar ubicación de scope personal en la doc oficial de subagents, no asumida.
  b. Modelo pineado en frontmatter: sonnet.
  c. Contrato: lee budget_log.jsonl completo, SESSION_STATE.md y los commits de la sesión auditada; verifica schemas del logging, exclusiones de calibración, gating aplicado y criterios del §6; hallazgos con evidencia textual del log; propone cambios al spec solo como texto con bump de versión, jamás los aplica.
  d. Regla dura doble: nunca audita quien ejecutó los bloques auditados; el contrato le prohíbe usar cualquier cosa fuera de los artefactos en disco listados (budget_log.jsonl, SESSION_STATE.md, commits). La independencia sale de eso, no de buena voluntad.
  e. Trigger: a demanda, integrado al prompt de Budget report del §5. Sin auto-trigger por session_end (peor momento para gastar pool; tras un limit_hit ni existe la oportunidad). | dep: ninguno (puede ir en paralelo a B4-B7)
- [MECHANICAL] S 5 — B9: instalar `budget-auditor` y sumarlo al spec (references/SPEC.md) como deliverable de nivel usuario (install-if-absent, como el statusline), con bump de versión y commit. | dep: B8

## In progress
(none)

## Completed
- [MECHANICAL] S — B1: scaffold session-budget (SKILL.md, references/SPEC.md, README.md, LICENSE, .gitignore) | commit 6e7a450 | session % 57→58 | actual 1 punto
- [MECHANICAL] S — B2: git init (main), primer commit, gh repo create --public, push, resync references/SPEC.md a v13 (canónico pasa a ser este repo, Downloads deja de leerse como fuente) | commit 6e7a450 | session % 58→9 (spans_reset: la ventana de 5h resetió durante el bloque, actual no válido) | actual null
- [MECHANICAL] M — B3: CLAUDE.md (protocolo, idéntico a §1.2 verificado), SESSION_STATE.md, budget_log.jsonl, .claude/agents/implementer.md; tests §4 6/7/8 verdes | commit af48c95 | session % 9→10 | actual 1 punto

## Cost calibration
<!-- medians by (size, model) from budget_log.jsonl, e.g. S/Sonnet=4, M/Sonnet=9, M/Fable=14 -->
<!-- defaults when no data: S=5 M=12 L=25 | current buffer=10 cap=20 -->
Sin datos suficientes todavía (2 actuales no-null: B1=1, B3=1; B2 excluido por spans_reset). Se sigue con defaults S=5 M=12 L=25, buffer=10, cap=20.

## Pending validation
- Primera auditoría formal con `budget-auditor` (una vez instalado en B9), a demanda, después del primer `session_end` en modo auto de este repo — sirve como validación del sistema completo (bootstrap + logging + gating) en un caso real.

## Minimal context to resume
- Repo: https://github.com/PabloPereiraBalestra/session-budget (skill package: SKILL.md + references/SPEC.md, canónico desde v13).
- Downloads/SESSION_BUDGET_SPEC.md y Downloads/REPO_TRUST_SPEC.md ya NO son fuente — cambiaron varias veces en vivo durante el bootstrap (v9→v10→v12→v13 acá). Toda edición futura del spec va en este repo (o en repo-trust para el otro spec), con bump + commit.
- repo-trust local: C:\Users\pablo\OneDrive\Documentos\GitHub\repo-trust ya tiene el protocolo aplicado sobre sí mismo y su propio references/SPEC.md — ese es el target de diff de B7, no Downloads.
- **CORRECCIÓN DESCUBIERTA 2026-07-04 (entorno cloud, container nuevo, sin usage_snapshot.json):** B4a, B4b, B5 y B6 de la pending list de abajo YA ESTÁN HECHOS — se ejecutaron y logearon dentro del propio repo `repo-trust` (su propio SESSION_STATE.md/budget_log.jsonl), no acá. Evidencia: preflight+resolve §0.3 (sin commit, research-only), escritura §1 deliverables + tests locales 1-7 (commit `e3aeb56`), push + tests post-push 8/9 (commit `decd340`), release v0.1.0 + test 10 SBOM (commit `0eef2c8`). Esta lista de pending blocks NO se actualizó todavía para reflejarlo — el usuario cerró la sesión antes de confirmar cómo reconciliar (dos preguntas quedaron sin responder, ver abajo). **Próxima sesión: no re-ejecutar B4a/B4b/B5/B6, arrancar reconciliando esto primero.**
- Preguntas pendientes de la sesión cortada, sin responder por el usuario:
  1. ¿Mover B4a/B4b/B5/B6 a Completed citando los commits de repo-trust, o dejarlo como está por ahora?
  2. B7 (empaquetar repo-trust como skill en `~/.claude/skills/repo-trust`) pide diff byte a byte contra `C:\Users\pablo\OneDrive\Documentos\GitHub\repo-trust\references\SPEC.md` — inalcanzable desde un container cloud. Opciones planteadas: generar el skill acá y dejar el diff pendiente para local / redefinir el test contra el `references/SPEC.md` ya clonado acá / posponer B7 y saltar a B8.
- Nota de entorno: este container cloud es un home directory nuevo — sin `~/.claude/usage_snapshot.json` ni `statusLine` en `~/.claude/settings.json`. Esperado (se instalaron en la máquina local, no acá), no una anomalía. No confirmado si este runtime cloud siquiera soporta el hook `statusLine` igual que la CLI local.
- Orquestador de la sesión anterior (con snapshot local): Sonnet 5. Fable capado al 95% del límite semanal esa semana — no relevante mientras el orquestador sea Sonnet/Opus.
- Sesión cloud cerrada 2026-07-04 por user_cut, modo manual, 0 bloques ejecutados (solo preflight + discovery de la corrección de arriba, sin cambios en el repo). Próximo bloque real: resolver la reconciliación de arriba, después B7 (con la decisión tomada) o B8 si se pospone B7.
