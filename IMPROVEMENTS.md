# IMPROVEMENTS

Backlog de ideas para el protocolo/skill session-budget. Distinto de `SESSION_STATE.md`:
esa lista trackea bloques ya planificados dentro de una sesión en curso; esta lista junta
ideas sueltas de mejora o funcionalidad nueva hasta que se decide traerlas a un bloque real
(y de ahí, potencialmente, a un bump de `references/SPEC.md`).

Flujo: idea entra en **Propuestas** → se discute con el usuario → pasa a **Aceptadas**
(candidata a bloque [DESIGN] o [MECHANICAL] en una sesión futura) o **Descartadas** (con
motivo, para no reproponerla sin contexto) → cuando se implementa y se refleja en la spec,
pasa a **Shipped** citando la versión de spec y el commit.

## Propuestas
<!-- idea nueva, sin triage todavía -->
(vacío)

## Aceptadas
<!-- confirmadas por el usuario, esperando entrar a un backlog de sesión -->
(vacío)

## Descartadas
<!-- idea + motivo, para no reabrir sin contexto nuevo -->
- **Política "Fable lane"** (delegar [MECHANICAL] a agentes Fable cuando el Fable
  semanal tiene margen, asumiendo que es capacidad casi gratis para el pool de 5h).
  Descartada 2026-07-06 tras el experimento medido B21-B24 (ver
  `references/FABLE_FEE_FINDINGS.md`): en la comparación controlada, delegar a Fable
  costó ~4x más five_hour por token que delegar a Sonnet (+11pts/62k tokens vs
  +4pts/90k tokens) — la observación original que motivó la idea probablemente
  confundía el pool de 5h con el Fable semanal (ese sí se movió solo con el agente
  Fable, pero apenas +1pt). Condición de reapertura: una medición futura con más
  muestras (mismo tipo de tarea en ambos modelos, distintos tamaños de bloque) que
  muestre lo contrario.
- **Historial de uso (serie temporal, `usage_history.jsonl` desde el statusline).**
  Descartada 2026-07-05: el proxy usado-vs-transcurrido (con `resets_at` + largo de
  ciclo conocido) cubre el pacing sin tocar el statusline ni gestionar throttle y
  rotación de archivos. Condición de reapertura explícita: si la proyección lineal
  resulta insuficiente en la práctica (consumo muy a ráfagas que la proyección
  malinterpreta), se reabre con esa evidencia.

## Shipped
<!-- idea + versión de spec donde se incorporó + commit -->
- **Medición del "Fable fee"** — bloques B21-B24 (2026-07-06), commits f97f7f4
  (script + baseline), bf1463d (diseño), b42b114 (implementación Fable), a3da96b
  (control Sonnet). Resultado y recomendación en `references/FABLE_FEE_FINDINGS.md`
  y en Descartadas de arriba. No generó bump de spec (la política que motivaba la
  medición no se sostuvo).
- **Asignador de tokens entre proyectos activos** — bloques B22-B24 (2026-07-06),
  entregable en `~/.claude/portfolio/` (fuera de repo, mismo precedente que el skill
  repo-trust de B7): `DESIGN.md`, `assign.ps1`, `projects.json`, `README.md`,
  `tests/` (31/31 tests propios). No requirió bump de spec — vive fuera del schema
  de este protocolo, es una herramienta de portfolio que lo consume.
- **Reporte obligatorio de reglas de segundo orden + Cost calibration como fuente
  única** — spec v23, commit 756bb05 (B19, 2026-07-05). Propuesto por budget-auditor
  tras auditar 15e13e1..HEAD: el umbral de ≥10 actuals ya se había cruzado sin
  evaluar las 3 condiciones, y un recap paralelo en SESSION_STATE.md se había
  desincronizado de la sección canónica.
- **Guard de ciclo transcurrido para la alerta de pared** — spec v22, commit d0fbf32
  (B18, 2026-07-05). Umbral ≥25% de ciclo transcurrido antes de disparar, corrige el
  falso positivo del dogfooding B15-B16.
- **Paralelizar bloques independientes** — spec v21, commit cd82142 (B17,
  2026-07-05). Subsección "Parallel lanes (conditioned)": lanes elegibles
  [MECHANICAL] con deps completadas + alcance disjunto, gate = suma de estimados del
  lote + buffer, cada línea `"parallel":true`. Hard-gate en ≥10 actuals no-null
  calificados (hoy 7 — feature dormida hasta que madure la calibración).
- **Reportes esquemáticos con emoticones** — spec v20, commit d2e87f9 (B16,
  2026-07-05). §5.1 con templates prescriptivos (checkpoint, cierre, resume) y
  leyenda ✅⚠️🛑🔄📉📈⏸️, vinculante desde §1.2.
- **Monitor unificado de allowances** — spec v19, commit 0882c85 (B15, 2026-07-05).
  Fusionó 4 propuestas (recordatorio ultrareview, aviso de límite por vencer,
  gate/pacing semanal, quemar margen que expira) en la subsección "Allowance pacing"
  de §1.2 + deliverable §1.7 `~/.claude/allowances.json`. Incluyó de yapa: no-go
  consciente del reset (<30 min), campo `effort` en el schema de block lines, y fix
  de staleness para writes de otra ventana viva de la cuenta.
- **No-go consciente del reset** — spec v19, commit 0882c85 (B15, 2026-07-05).
- **Guardarraíles de calibración** — spec v18, commit c5e5c7f (B14, 2026-07-05). Un
  bucket necesita ≥3 actuals calificados para pisar el nivel de fallback inferior;
  actuals=0 cuentan siempre; parallel/spans_reset son las únicas exclusiones válidas
  (sin drops discrecionales).
