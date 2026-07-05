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
(vacío — triage completo 2026-07-05, ver Aceptadas/Descartadas)

## Aceptadas
<!-- confirmadas por el usuario, esperando entrar a un backlog de sesión -->
- **Monitor unificado de allowances** (fusiona 4 propuestas: recordatorio ultrareview,
  aviso de límite por vencer sin usar, gate/pacing semanal `seven_day`, quemar margen
  que expira). Aprobado 2026-07-05. Diseño resuelto: una sola mecánica (ciclo, tiempo
  a reset, % usado, proyección lineal usado-vs-transcurrido) sobre N límites;
  `five_hour`/`seven_day` desde el snapshot (costo extra cero, ya se lee en cada
  checkpoint), ultrareview desde registro manual `~/.claude/allowances.json`
  (`{"ultrareview":{"quota":3,"used":n,"resets":"<fecha ciclo facturación>"}}` — el
  usuario declara la fecha una vez, el orquestador incrementa `used` al observar una
  corrida). Alertas: *desperdicio* (transcurrido ≥70% del ciclo y proyección <60% al
  reset → sugerir consumir: adelantar MECHANICAL baratos, auditoría budget-auditor,
  corridas gratis de ultrareview pendientes) y *pared* (solo seven_day: proyección
  ≥100% antes del reset → recomendar orquestador sonnet, diferir DESIGN pesados).
  Frecuencia: solo resume y checkpoints, nunca proactivo mid-bloque. Incluye el no-go
  consciente del reset (abajo). → bloque B15 [DESIGN].
- **No-go consciente del reset.** Aprobado 2026-07-05. Resuelto: no cambia la
  semántica del gate, solo el reporte — si al momento del no-go faltan <30 min para
  `resets_at`, recomendar esperar y arrancar con ventana llena en vez de cerrar.
  Viaja dentro del bump del monitor de allowances. → bloque B15 [DESIGN].
- **Reportes esquemáticos con emoticones.** Aprobado 2026-07-05. Resuelto: templates
  fijos por tipo de reporte (checkpoint de bloque, cierre de sesión, resume) en un
  §5.1 nuevo, prescriptivo en la spec (no a criterio del orquestador, para que no
  derive entre modelos/sesiones). Leyenda: ✅ limpio, ⚠️ trending over, 🛑 no-go,
  🔄 spans_reset, 📉 margen ocioso, 📈 riesgo de pared. → bloque B16 [DESIGN].
- **Paralelizar bloques independientes cuando el uso está bajo.** Aprobado 2026-07-05
  con condiciones. Resuelto: lanes elegibles = [MECHANICAL] con dependencias
  completadas y alcance de archivos disjunto; gate por lote = suma de estimados de
  todos los lanes + buffer (nunca el máximo: el pool es compartido, la concurrencia
  divide el tiempo de pared, no el costo); cada línea de log lleva `"parallel":true`
  (fuera de calibración, regla existente). Condición dura: habilitado solo con fase
  de calibración completa (≥10 actuals no-null) — paralelizar sacrifica dato de
  calibración a cambio de throughput; hoy (6 actuals) no se activaría. Encaja como
  acción de la alerta de desperdicio del monitor. → bloque B17 [DESIGN], último
  (inactivo hasta que madure la calibración).

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
- **Guardarraíles de calibración** — spec v18, commit c5e5c7f (B14, 2026-07-05). Un
  bucket necesita ≥3 actuals calificados para pisar el nivel de fallback inferior;
  actuals=0 cuentan siempre; parallel/spans_reset son las únicas exclusiones válidas
  (sin drops discrecionales).
