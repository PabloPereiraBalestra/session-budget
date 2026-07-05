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
- **Paralelizar bloques independientes cuando el uso está bajo.** Si el % usado de la
  ventana de 5h es bajo y el backlog tiene varios bloques sin dependencia entre sí (ver
  el orden por dependencia en `SESSION_STATE.md`), evaluar correrlos en paralelo (varios
  subagentes/lanes a la vez) en vez de uno a la vez, para aprovechar el margen.
  Cuidado: el pool de 5h es account-wide — si el usuario tiene otros proyectos o
  sesiones corriendo en paralelo (otra ventana de Claude Code, claude.ai, Cowork), esos
  consumen del mismo presupuesto y hay que seguir marcando `"parallel":true` en cada
  línea de log afectada (regla ya existente en §1.2). Abierto: cómo detectar "hay
  múltiples lanes ejecutables" (¿todas las [MECHANICAL] sin dependencia pendiente
  entre sí?) y cuánto margen de uso alcanza para justificar paralelizar sin arriesgar
  el go/no-go de los bloques restantes.
- **Reportes más esquemáticos, con formato y emoticones.** Los reportes del protocolo
  (resumen de bloque, cierre de sesión, "Budget report" de §5) hoy son texto corrido en
  prosa. Pasarlos a un formato tabular/esquemático fijo (bullets o tabla: bloque, tag,
  tamaño, % inicio→fin, estado) con emoticones como señal visual rápida (✅ bloque
  limpio, ⚠️ trending over estimate, 🛑 no-go, 🔄 spans_reset) para escanear el estado
  de un vistazo. Abierto: definir el template exacto por tipo de reporte (checkpoint de
  bloque vs. cierre de sesión vs. resume) y si esto vive en §5 del spec como formato
  prescriptivo o queda a criterio del orquestador.

## Aceptadas
<!-- confirmadas por el usuario, esperando entrar a un backlog de sesión -->
(vacío)

## Descartadas
<!-- idea + motivo, para no reabrir sin contexto nuevo -->
(vacío)

## Shipped
<!-- idea + versión de spec donde se incorporó + commit -->
(vacío)
