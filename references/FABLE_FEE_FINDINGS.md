# Hallazgos del experimento Fable-fee (B21-B24)

Informe de B25. Datos crudos en `fable_fee_log.jsonl` (raíz del repo, 5 lecturas:
`baseline`, `pre_b23`, `post_b23`, `pre_b24`, `post_b24`).

## Motivación

`IMPROVEMENTS.md` registraba una observación informal: "dos agentes Fable (~200k
tokens combinados) movieron el pool de 5h de Sonnet solo 1 punto (62%→63%)". Si eso
fuera representativo, delegar bloques [MECHANICAL] a agentes Fable cuando el Fable
semanal tiene margen sería capacidad casi gratis para la ventana de 5h — de ahí la
idea de una política "Fable lane" en el protocolo.

Este experimento instrumentó una comparación controlada: el mismo asignador de
portfolio (diseñado en B22), implementado por un agente Fable (B23) y luego
testeado/documentado por un agente Sonnet como control (B24), midiendo los 3
medidores relevantes (five_hour de cuenta, seven_day all-models, Fable semanal)
antes y después de cada delegación.

## Datos

| Bloque | Modelo del subagente | subagent_tokens | tool_uses | five_hour Δ | seven_day (all-models) Δ | Fable semanal Δ |
|---|---|---|---|---|---|---|
| B23 | Fable 5 | 62,308 | 14 | **+11** (28→39) | +1 (24→25) | +1 (23→24) |
| B24 | Sonnet 5 | 90,673 | 37 | **+4** (39→43) | +1 (25→26) | +0 (24→24) |

Tasa five_hour por token:
- B23 (Fable): 11 / 62,308 ≈ **1.77 puntos por cada 10k tokens**
- B24 (Sonnet): 4 / 90,673 ≈ **0.44 puntos por cada 10k tokens**

B23 costó ~4x más five_hour por token que B24, pese a que B24 hizo más trabajo real
(más tokens, más del doble de tool calls).

## Interpretación

**La hipótesis original NO se confirma — el resultado apunta en la dirección
contraria.** En esta comparación:

1. El pool de five_hour (el que gatea este protocolo) se movió **más**, no menos,
   cuando el trabajo se delegó a Fable — tanto en términos absolutos (+11 vs +4)
   como normalizado por token (~4x).
2. El Fable semanal sí se movió exclusivamente con el agente Fable (+1 vs +0 del
   control Sonnet) — eso confirma que ese medidor específico está atado al modelo,
   como se esperaba. Pero el monto es chico (1 punto) incluso para una tarea
   sustancial — coherente con la observación original de "casi gratis", **si esa
   observación se refería al pool semanal de Fable y no al de 5h**. Es la
   explicación más simple del aparente contraste: probablemente la nota original
   confundió qué medidor se había movido poco.
3. Conclusión práctica: delegar [MECHANICAL] a un agente Fable no libera margen del
   pool de 5h — en esta medición, lo consume más rápido que delegar a Sonnet. La
   política "Fable lane" tal como se propuso (explotar margen de Fable semanal como
   capacidad casi gratis para la ventana de 5h) **no tiene sustento en este dato**.

## Limitaciones (n=1 por modelo, léase con cautela en la magnitud, no en la dirección)

- Un solo punto de dato por modelo — la propia calibración de este proyecto ya
  muestra error mediano de estimación de 40-60%+ en buckets con pocos datos
  (ver `SESSION_STATE.md` → Cost calibration). La magnitud exacta (4x) puede no
  repetirse, pero la dirección (Fable no es más barato en five_hour) es una
  diferencia grande, no un empate technical.
- B23 y B24 son tareas distintas (implementación vs. tests/docs) y de tamaño
  distinto (M vs S) — parte de la diferencia podría deberse a la forma de la tarea,
  no solo al modelo. No se controló por tipo de tarea.
- No se puede descartar del todo contaminación paralela de otra ventana de la cuenta
  durante el intervalo — se detectó una escritura de `usage_snapshot.json` desde
  otra sesión (proyecto `initium`) en el preflight de esta misma sesión, antes de
  que arrancara el experimento. Los chequeos de `session_id` en los extremos de
  cada medición (pre/post) no mostraron esa contaminación durante B23/B24
  específicamente, pero solo son fotos, no cobertura continua del intervalo.
- Ambos subagentes heredaron el effort de la sesión (auto) sin override explícito —
  no se controló el nivel de effort por separado del modelo.

## Recomendación

- **No** adoptar la política "Fable lane" de delegación automática tal como estaba
  planteada en `IMPROVEMENTS.md`. Mover esa idea de "Aceptadas" a "Descartadas" con
  esta evidencia, dejando condición de reapertura explícita: si una medición futura
  con más muestras (distintos tamaños de bloque, mismo tipo de tarea en ambos
  modelos) muestra lo contrario, reabrir.
- El campo `agent_model` en el schema de líneas de bloque (usado ad-hoc en esta
  sesión para B23/B24, ver notas en `budget_log.jsonl`) sí demostró ser útil para
  este tipo de medición y es independiente de si la política "Fable lane" se adopta
  o no — vale la pena proponerlo como bump de spec menor (registra qué modelo
  ejecutó el trabajo delegado, sin implicar ninguna política de decisión). Texto
  propuesto para aprobación del usuario, no commiteado todavía (regla dura del
  protocolo: cambios estructurales solo con aprobación explícita).
- El asignador de portfolio (B22-B24) sigue siendo válido y útil independientemente
  de este resultado — su recomendación de modelo ya cae automáticamente a "sonnet"
  para bloques MECHANICAL sin margen fresco de Fable semanal, lo cual, a la luz de
  este hallazgo, es probablemente el comportamiento correcto por defecto de todos
  modos.
