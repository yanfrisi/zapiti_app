# Plan de implementación — Zapiti v0.2.0

**IA avanzada de bots, señal «Ven a mí» y sistema completo de Truco**

**Estado:** Propuesta para implementación  
**Versión base:** `0.1.0+1`  
**Versión objetivo recomendada:** `0.2.0+2`  
**Ámbito:** aplicación Flutter + servidor multijugador  

> Este documento debe utilizarse como plan de trabajo. La IA debe analizar primero la implementación actual, ejecutar los cambios por fases, no hacer `commit` ni `push` automáticamente y no continuar si los tests de una fase fallan.

---

## 1. Objetivo general

Preparar una nueva versión de Zapiti que mejore de forma medible la toma de decisiones de los bots, incorpore la señal **«Ven a mí»** y corrija el sistema de apuestas para que respete la alternancia real de la escalera:

`Truco → Seis → Nueve → Doce → Quince → Ahorrisi`

La implementación debe mantener estas prioridades:

1. Reglas correctas y centralizadas.
2. Servidor autoritativo en multijugador.
3. Ninguna acción ilegal.
4. IA sin acceso a cartas ocultas.
5. Rendimiento estable en teléfonos reales.
6. Cambios pequeños, comprobables y reversibles.

---

## 2. Alcance funcional

### 2.1 Mejora de la IA de cartas

La IA debe dejar de depender únicamente de reglas locales o de una cadena extensa de condiciones. Se implementará un enfoque híbrido:

- Política heurística robusta como base y mecanismo de respaldo.
- Simulación de estados completos mediante copias puras del juego.
- Determinización de cartas ocultas compatibles con la información conocida.
- **Information Set Monte Carlo Tree Search (ISMCTS)** para los niveles de dificultad superiores.
- Semillas aleatorias configurables para que los tests sean reproducibles.

No se utilizarán redes neuronales ni servicios externos de inteligencia artificial. Actualmente no existe un conjunto de partidas etiquetadas suficiente para entrenar un modelo con garantías, y esa complejidad no aportaría una mejora justificable.

### 2.2 Nueva señal «Ven a mí»

La señal indica:

> «Yo intentaré ganar esta baza; mi compañero debe jugar su carta más baja».

Comportamiento requerido:

- Si el compañero es bot, juega la carta legal más baja según la jerarquía real del Zapiti.
- Si el compañero es humano, se muestra la señal y una instrucción clara, pero no se fuerza ninguna carta.
- La señal afecta únicamente a la baza actual.
- Se limpia cuando el compañero juega o cuando termina la baza.
- En multijugador, el servidor valida y distribuye la señal.

### 2.3 Sistema de Truco completo

Reglas objetivo:

- Escalera: `Truco → Seis → Nueve → Doce → Quince → Ahorrisi`.
- Truco propone jugar la mano por 3 chinos.
- Aceptar no cierra las apuestas.
- El equipo que acepta puede subir posteriormente cuando le corresponda el turno.
- Un mismo equipo no puede subir dos veces consecutivas.
- Tras cada subida, el derecho de volver a subir pasa al equipo rival.
- Una propuesta pendiente permite aceptar, rechazar o contra-subir.
- Responder está permitido aunque no sea el turno normal de jugar carta.
- Iniciar una subida sin propuesta pendiente solo está permitido en el turno correspondiente.
- La apuesta afecta a toda la mano de hasta tres bazas y no se reinicia entre ellas.

### 2.4 Multijugador autoritativo

El cliente nunca decide de forma definitiva que una acción es válida. El servidor debe validar:

- Identidad y pertenencia del jugador.
- Partida y estado actual.
- Turno.
- Equipo.
- Nivel siguiente permitido.
- Último equipo que subió.
- Propuesta pendiente y equipo que debe responder.
- Duplicados y acciones con una versión de estado antigua.

---

## 3. Decisiones técnicas obligatorias

### 3.1 Fuente única de reglas

La IA y la interfaz deben consultar al motor de reglas. No deben duplicar condiciones.

```dart
abstract interface class LegalActionProvider {
  List<Card> legalCards(GameObservation observation);
  List<BetAction> legalBetActions(GameObservation observation);
}
```

La IA selecciona entre acciones legales; no redefine cuándo puede jugar, trucar, subir o responder.

### 3.2 Observación limitada para bots

```dart
class BotDecisionContext {
  final PlayerId botId;
  final TeamId botTeam;
  final List<Card> ownHand;
  final List<PlayedCard> playedCards;
  final List<Card> currentTrickCards;
  final PlayerId currentPlayer;
  final HandScore handScore;
  final BetState betState;
  final List<GameSignal> visibleSignals;
  final List<Card> remainingDeckCandidates;
}
```

No se permite incluir en este contexto:

- Manos actuales de rivales.
- Mano del compañero, salvo información pública o deducida legalmente.
- Datos internos invisibles para un jugador humano.
- Resultados aleatorios futuros.

### 3.3 Máquina de estados explícita para apuestas

```dart
enum BetLevel {
  none,
  truco,
  six,
  nine,
  twelve,
  fifteen,
  ahorrisi,
}

class BetState {
  final BetLevel acceptedLevel;
  final BetLevel? proposedLevel;
  final TeamId? proposingTeam;
  final TeamId? respondingTeam;
  final TeamId? lastRaisingTeam;
  final bool responsePending;
}
```

No se debe modelar el sistema únicamente con booleanos como `trucoAccepted`.

### 3.4 Estado versionado en multijugador

```dart
class GameCommand {
  final String gameId;
  final String playerId;
  final int expectedStateVersion;
}
```

El servidor incrementa `stateVersion` tras cada transición válida. Si un comando llega con una versión antigua, lo rechaza y devuelve el estado actual.

### 3.5 Comparador único de fuerza de cartas

Crear o reutilizar un componente equivalente a:

```dart
class CardStrengthComparator implements Comparator<Card> {
  @override
  int compare(Card a, Card b) {
    // Usa la jerarquía real del Zapiti.
  }
}
```

Nunca se debe asumir que la carta más baja es la de menor número impreso.

---

## 4. Arquitectura propuesta

### Dominio compartido o motor de reglas

- `LegalActionProvider`
- `CardStrengthComparator`
- `BetLevel`
- `BetState`
- `BetRules`
- `GameSignal`
- `GameObservation`
- Resolución de baza y mano

### Capa de IA

- `BotPolicy`
- `HeuristicBotPolicy`
- `HeuristicRolloutPolicy`
- `HiddenCardDeterminizer`
- `GameStateSimulator`
- `IsmctsBotPolicy`
- `BotDifficulty`
- `BotDecisionMetrics`

### Cliente Flutter

- Botón y visualización de «Ven a mí».
- Botones de Truco/subida según acciones legales recibidas.
- Modal de respuesta pendiente.
- Mensajes funcionales, no técnicos.
- Ejecución de búsquedas costosas fuera del hilo de interfaz.

### Servidor

- Validación autoritativa de apuestas.
- Validación de señales.
- Control de concurrencia y versión de estado.
- Persistencia del `BetState` en reconexiones.
- Emisión del estado completo a todos los clientes.

---

## 5. Plan de implementación por fases

### Fase 0 — Análisis y línea base

**Objetivo:** comprender el flujo actual sin modificar código.

La IA debe localizar y explicar:

- Función que decide la carta del bot.
- Representación y jerarquía de cartas.
- Cálculo de cartas y acciones legales.
- Resolución de baza y mano.
- Representación de equipos y turnos.
- Sistema actual de señas.
- Estado y transiciones actuales del truco.
- Mensajes cliente-servidor.
- Validaciones actuales del servidor.

**Entregables:**

- Flujo actual.
- Problemas detectados.
- Archivos afectados.
- Riesgos.
- Tests existentes reutilizables.
- Propuesta de clases nuevas.

**Puerta de salida:** no modificar nada hasta presentar este análisis.

### Fase 1 — Tests de caracterización y acciones legales

**Objetivo:** congelar el comportamiento válido y centralizar reglas.

Tareas:

1. Añadir tests del comportamiento actual de baza, mano y turno.
2. Crear o consolidar `LegalActionProvider`.
3. Crear `CardStrengthComparator`.
4. Hacer que UI, bots y servidor reutilicen las mismas reglas cuando sea viable.
5. Eliminar duplicaciones peligrosas, sin refactorización general.

**Criterios de aceptación:**

- Todas las cartas ofrecidas por el motor son legales.
- Ningún bot puede jugar una carta ajena.
- Las reglas de fuerza de carta tienen una única implementación.

### Fase 2 — Máquina de estados del Truco

**Objetivo:** representar correctamente niveles, propuestas y alternancia.

Tareas:

1. Implementar `BetLevel` y `BetState`.
2. Separar `acceptedLevel` y `proposedLevel`.
3. Registrar `lastRaisingTeam`.
4. Implementar las transiciones puras:
   - iniciar subida;
   - aceptar;
   - rechazar;
   - contra-subir.
5. Impedir saltos de nivel.
6. Mantener el estado entre bazas.
7. Reiniciarlo solo al comenzar una mano nueva.

**Reglas de transición:**

```dart
bool canInitiateRaise(Player player, GameState state) {
  return !state.betState.responsePending &&
      state.currentPlayerId == player.id &&
      state.betState.hasNextLevel &&
      state.betState.lastRaisingTeam != player.teamId;
}
```

Con propuesta pendiente:

- Se pausa el juego de cartas.
- El equipo desafiado puede aceptar, rechazar o contra-subir.
- La respuesta no exige ser el jugador que tenía el turno de carta.
- Solo se procesa la primera respuesta válida.

**Pendiente obligatorio:** confirmar la puntuación y resolución exacta de `Ahorrisi`. No inventarla.

### Fase 3 — Servidor autoritativo y protocolo multijugador

**Objetivo:** impedir acciones ilegales incluso desde clientes manipulados.

Tareas:

1. Añadir `stateVersion`.
2. Incluir `expectedStateVersion` en comandos.
3. Validar todas las transiciones de apuesta en servidor.
4. Rechazar:
   - subida fuera de turno;
   - nivel saltado;
   - mismo equipo subiendo dos veces;
   - respuesta del equipo incorrecto;
   - comandos duplicados o antiguos.
5. Emitir el estado completo tras una transición.
6. Restaurar `BetState` tras reconexión.
7. Garantizar procesamiento atómico de respuestas simultáneas.

### Fase 4 — Interfaz del Truco

**Objetivo:** mostrar únicamente acciones válidas y comprensibles.

Tareas:

- Mostrar el botón de iniciar/subir solo si `canInitiateRaise` es verdadero.
- Cuando haya propuesta pendiente, mostrar:
  - aceptar;
  - rechazar;
  - siguiente nivel, si existe.
- Bloquear temporalmente el juego de cartas durante la respuesta.
- Mostrar el nivel aceptado y la propuesta actual de forma diferenciada.
- No mostrar términos técnicos de red o servidor.

**Mensajes recomendados:**

- «El equipo rival ha cantado Truco».
- «¿Quieres aceptar, rechazar o subir?».
- «La apuesta sube a Seis».

### Fase 5 — Señal «Ven a mí»

**Objetivo:** coordinar al compañero sin alterar las reglas del turno.

Tareas:

1. Añadir `GameSignal.comeToMe`.
2. Añadir el botón «Ven a mí» en la interfaz de señas.
3. Guardar la señal con alcance de baza.
4. Limpiarla cuando el compañero juegue o termine la baza.
5. Enviar y validar la señal mediante el servidor.
6. Mostrar al compañero humano: «Tu compañero ha indicado “Ven a mí”. Juega tu carta más baja».
7. En compañero bot, aplicar prioridad absoluta:

```dart
if (context.hasActiveComeToMeFromPartner) {
  return weakestLegalCard;
}
```

### Fase 6 — Política heurística de bots

**Objetivo:** conseguir una mejora inmediata antes de añadir búsqueda compleja.

Orden recomendado de decisión:

1. Si existe «Ven a mí», jugar la carta legal más baja.
2. Si el compañero ya gana con alta seguridad, jugar la más baja.
3. Si puede ganar con varias, utilizar la ganadora más baja.
4. Evitar gastar una carta máxima cuando no cambia el resultado.
5. En baza decisiva, priorizar ganar la mano.
6. Con apuesta alta, reducir jugadas especulativas.
7. Considerar quién queda por jugar y qué cartas fuertes ya han salido.
8. Conservar cartas fuertes solo cuando aumente el valor esperado de la mano.

Crear:

```dart
abstract interface class BotPolicy {
  Card chooseCard(BotDecisionContext context);
}

class HeuristicBotPolicy implements BotPolicy { /* ... */ }
```

Esta política será también el `fallback` de ISMCTS.

### Fase 7 — Simulador puro y determinización

**Objetivo:** poder ejecutar miles de continuaciones sin tocar el estado real.

Crear:

- `GameStateSimulator`: copia inmutable o aislada del estado.
- `HiddenCardDeterminizer`: reparte cartas desconocidas de forma compatible.

Conjunto de cartas desconocidas:

```text
mazo completo
- mano propia
- cartas ya jugadas
- cartas públicamente conocidas
```

Restricciones:

- Respetar el número de cartas restante de cada jugador.
- No crear repartos imposibles.
- No consultar las manos reales del estado de producción.
- Permitir `Random(seed)` en tests.

### Fase 8 — ISMCTS

**Objetivo:** elegir la acción con mejor resultado esperado para toda la mano.

Proceso por decisión:

1. Obtener acciones legales.
2. Generar una determinización válida.
3. Copiar el estado.
4. Ejecutar selección mediante UCT.
5. Expandir una acción no explorada.
6. Simular con `HeuristicRolloutPolicy`.
7. Evaluar el resultado para el equipo del bot.
8. Retropropagar.
9. Repetir hasta agotar tiempo o simulaciones.
10. Elegir la acción más visitada o de mayor valor medio, según configuración.

La utilidad terminal debe medir el resultado real de la mano:

```dart
double terminalUtility(SimulatedGame game, TeamId botTeam) {
  return game.scoreFor(botTeam) - game.scoreAgainst(botTeam);
}
```

En estados no terminales por límite de tiempo, valorar:

- bazas ganadas;
- estado de la baza actual;
- cartas restantes estimadas;
- nivel de apuesta;
- probabilidad de ganar la mano.

No premiar una baza aislada si sacrifica la mano completa.

### Fase 9 — Dificultades y rendimiento

Configuración inicial:

| Dificultad | Estrategia | Presupuesto inicial |
|---|---|---|
| Fácil | Heurística | Sin búsqueda |
| Normal | ISMCTS + heurística | 300–800 simulaciones, objetivo ≤ 100 ms |
| Difícil | ISMCTS + heurística | 1000–3000 simulaciones, objetivo ≤ 250 ms |

Estas cifras son provisionales y deben ajustarse con mediciones reales.

La búsqueda no debe bloquear la interfaz. Usar `Isolate` o un mecanismo equivalente cuando sea necesario.

Si la búsqueda falla o excede el presupuesto, usar `HeuristicBotPolicy` y continuar la partida.

### Fase 10 — Benchmarks y ajuste

Ejecutar miles de manos reproducibles:

- IA nueva contra IA antigua.
- IA nueva contra política aleatoria.
- IA nueva contra heurística sin búsqueda.

Medir:

- Porcentaje de manos ganadas.
- Diferencia media de puntos/chinos.
- Cartas altas desperdiciadas.
- Tiempo medio y máximo de decisión.
- Uso de fallback.
- Acciones ilegales: debe ser cero.

No considerar la IA mejorada por tener más código. Debe demostrar resultados superiores.

### Fase 11 — Integración, regresión y versión

Tareas:

1. Ejecutar todos los tests de Flutter y servidor.
2. Probar partidas individuales completas.
3. Probar multijugador con cuatro dispositivos/clientes.
4. Probar pérdida y recuperación de conexión.
5. Probar respuestas simultáneas.
6. Revisar que la apuesta persiste entre bazas.
7. Revisar que «Ven a mí» no persiste de forma indebida.
8. Incrementar versión recomendada a:

```yaml
version: 0.2.0+2
```

9. Generar APK release y AAB firmado.
10. Publicar primero en prueba interna.

---

## 6. Matriz de tests obligatorios

### IA

- El bot solo juega cartas de su mano.
- El bot solo elige acciones legales.
- El bot no recibe las manos reales de rivales.
- «Ven a mí» obliga al compañero bot a jugar la carta legal más baja.
- Sin la señal, no existe esa obligación.
- Si el compañero ya gana, el bot evita malgastar una carta alta.
- Si varias cartas ganan, prefiere la ganadora más baja cuando el resultado esperado es equivalente.
- La misma semilla produce la misma decisión.
- La búsqueda respeta el límite de tiempo.
- El fallback funciona.
- La interfaz no se bloquea.
- La evaluación considera la mano, no solo la baza.

### Señales

- «Ven a mí» solo llega al compañero.
- Se limpia cuando el compañero juega.
- Se limpia al finalizar la baza.
- No permanece en la siguiente baza.
- El humano ve la indicación.
- El bot ejecuta la carta más baja.
- Un jugador ajeno no puede enviarla.

### Truco

- A canta Truco.
- B acepta.
- La mano continúa.
- A no puede subir inmediatamente a Seis.
- B puede subir a Seis cuando llegue su turno.
- A puede aceptar, rechazar o contra-subir a Nueve.
- No se saltan niveles.
- El mismo equipo no sube dos veces seguidas.
- No se inicia una subida fuera de turno.
- Sí se puede responder fuera del turno normal.
- Una propuesta pendiente pausa el juego de cartas.
- Respuestas simultáneas no corrompen el estado.
- El nivel aceptado persiste entre bazas.
- El estado se reinicia en una mano nueva.
- Ahorrisi solo aparece después de Quince.
- No existe nivel posterior a Ahorrisi.

### Integración multijugador

- Cliente manipulado intenta subir fuera de turno: rechazado.
- Cliente intenta saltar de Truco a Nueve: rechazado.
- Dos compañeros responden simultáneamente: solo una respuesta válida.
- Comando con `stateVersion` antigua: rechazado y resincronizado.
- Tras reconexión se recupera el `BetState` completo.
- Una propuesta pendiente sigue visible tras reconexión.
- La señal se conserva únicamente durante su alcance válido.

---

## 7. Criterios de aceptación

La versión estará lista cuando:

- Todas las reglas de apuesta estén cubiertas por tests.
- Aceptar no cierre futuras subidas.
- Ningún equipo pueda subir dos veces seguidas.
- Iniciar/subir requiera turno y responder no.
- El servidor rechace todas las transiciones ilegales.
- «Ven a mí» funcione con compañero bot y humano.
- Los bots no lean información oculta.
- La IA nueva supere de forma consistente a la antigua y a la aleatoria.
- No existan acciones ilegales en benchmarks.
- El tiempo de decisión sea aceptable en un teléfono real.
- `flutter analyze`, `flutter test` y tests del servidor pasen.
- El APK release y el AAB firmado se generen correctamente.

---

## 8. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| La IA bloquea la interfaz | Ejecutar búsqueda fuera del hilo principal y aplicar límite estricto |
| Los bots hacen trampas | Contexto limitado y tests que impidan acceso a manos ocultas |
| Reglas duplicadas entre cliente y servidor | Fuente única de acciones legales y servidor autoritativo |
| Respuestas simultáneas corrompen el estado | Transacciones atómicas y `stateVersion` |
| ISMCTS es demasiado lento | Política heurística, límites por tiempo y fallback |
| El algoritmo parece mejor pero no lo es | Benchmarks reproducibles frente a IA antigua y aleatoria |
| La apuesta se reinicia entre bazas | Tests específicos de persistencia dentro de la mano |
| «Ven a mí» queda activa demasiado tiempo | Alcance explícito de baza y limpieza en dos eventos |
| Ahorrisi está mal definido | No implementar su valor final sin confirmación funcional |

---

## 9. Orden obligatorio de trabajo para la IA

1. Analizar sin modificar.
2. Crear tests de caracterización.
3. Centralizar acciones legales.
4. Implementar máquina de estados del Truco.
5. Hacer autoritativo el servidor.
6. Adaptar la interfaz.
7. Añadir «Ven a mí».
8. Crear política heurística.
9. Crear simulador y determinización.
10. Implementar ISMCTS.
11. Medir, comparar y ajustar.
12. Ejecutar regresión completa.
13. Preparar la versión release.

No implementar todo en un único cambio. Después de cada fase:

- Mostrar archivos modificados.
- Explicar las decisiones.
- Ejecutar tests.
- Detenerse si existe un fallo.
- No hacer `commit` ni `push` automáticamente.

---

## 10. Entrega final esperada de la IA

La IA deberá entregar:

1. Análisis inicial del código.
2. Lista de archivos modificados.
3. Clases nuevas y responsabilidades.
4. Tests añadidos.
5. Resultado de `flutter analyze`.
6. Resultado de `flutter test`.
7. Resultado de tests del servidor.
8. Benchmarks de IA nueva frente a IA anterior y aleatoria.
9. Tiempo medio y máximo de decisión.
10. Confirmación de cero acciones ilegales.
11. Confirmación de que los bots no reciben cartas ocultas.
12. Confirmación de validación autoritativa del servidor.
13. Problemas pendientes, especialmente la definición exacta de Ahorrisi.
14. Ruta del APK release y del AAB firmado.

---

## 11. Instrucción final para ejecutar el plan

> Analiza primero la implementación actual y presenta el informe de la Fase 0. No modifiques archivos hasta que el análisis esté completo. Después aplica el plan fase a fase, con cambios mínimos y tests obligatorios. No inventes reglas, especialmente el valor de Ahorrisi. No hagas commit, push ni despliegues automáticamente.
