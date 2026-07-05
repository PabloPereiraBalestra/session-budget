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
- **Asignador de tokens entre proyectos activos (portfolio-level).** Propuesto por el
  usuario 2026-07-05. Una funcionalidad que ayude a decidir cómo distribuir los tokens
  del plan entre los proyectos activos: qué proyecto recibe la próxima ventana, con qué
  modelo y con qué esfuerzo. Hoy session-budget optimiza dentro de un proyecto; esta
  capa optimiza entre proyectos, cruzando (a) el backlog de cada uno (bloques
  [DESIGN]/[MECHANICAL] pendientes y sus tamaños, de cada SESSION_STATE.md), (b) la
  calibración de costo por modelo de cada budget_log.jsonl, (c) el estado de todos los
  límites (five_hour, seven_day, semanal por modelo, allowances tipo ultrareview) y
  (d) prioridades/deadlines declarados por el usuario. Output tipo: "Fable expira en
  2,5h con 90% libre → quemalo en los [DESIGN] del proyecto X a effort high; los
  [MECHANICAL] de Y van a sonnet effort medium; Z puede esperar al reset semanal".
  Caso real que la motiva: la decisión de hoy sobre dónde gastar el Fable semanal
  expirante se hizo a mano en la conversación. Encaja con la directiva de apps
  externas: puede ser un dashboard/script fuera de Claude Code que lea los repos con
  el protocolo instalado + el snapshot. Abierto: dónde vive (¿registro de proyectos
  activos en ~/.claude/ leído por cualquier sesión, skill separada, o app externa?);
  de dónde salen los límites semanales por modelo que el snapshot no expone (¿input
  manual del usuario, o scrape de la página de usage de claude.ai?); el protocolo hoy
  no logea effort por bloque — ¿agregar campo "effort" al schema de block lines (el
  snapshot ya expone effort.level) para poder calibrar costo por (size, model,
  effort)?; y cómo captura prioridades entre proyectos sin volverse un PM tool.
  Nota 2026-07-05: el campo "effort" ya shippeó en v19 (B15); el resto sigue abierto.
- **Guard de ciclo transcurrido para la alerta de pared.** Detectado en el primer
  dogfooding del monitor v19 (checkpoint de B15): la alerta de desperdicio exige
  ≥70% de ciclo transcurrido, pero la de pared (seven_day proyección ≥100%) no tiene
  guard equivalente — con 12% del ciclo transcurrido, un día atípico proyecta >100%
  y dispara falsos positivos puro ruido. Abierto: umbral mínimo de ciclo transcurrido
  para que la proyección de pared sea accionable (¿≥30%?), o suavizar la acción
  recomendada cuando el ciclo es joven.

## Aceptadas
<!-- confirmadas por el usuario, esperando entrar a un backlog de sesión -->
## Descartadas
<!-- idea + motivo, para no reabrir sin contexto nuevo -->
- **Historial de uso (serie temporal, `usage_history.jsonl` desde el statusline).**
  Descartada 2026-07-05: el proxy usado-vs-transcurrido (con `resets_at` + largo de
  ciclo conocido) cubre el pacing sin tocar el statusline ni gestionar throttle y
  rotación de archivos. Condición de reapertura explícita: si la proyección lineal
  resulta insuficiente en la práctica (consumo muy a ráfagas que la proyección
  malinterpreta), se reabre con esa evidencia.

## Shipped
<!-- idea + versión de spec donde se incorporó + commit -->
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
