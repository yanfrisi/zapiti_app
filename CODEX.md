# Instrucciones para Codex

## Contexto

Zapiti es un juego de cartas Flutter funcional, con partida local contra bots y
modo multijugador. Ya no es un prototipo inicial.

## Arquitectura

- `lib/domain`: modelos y reglas puras del juego.
- `lib/screens`: pantallas, coordinacion visual y entrada del usuario.
- `lib/widgets`: componentes visuales reutilizables.
- `lib/multiplayer`: protocolo y cliente multijugador.
- `test/domain`: pruebas unitarias de reglas.

No dupliques reglas en widgets. Local y multijugador deben usar el mismo
dominio siempre que el servidor no sea la autoridad de una accion.

## Reglas consolidadas

- Juegan dos equipos de dos jugadores.
- Cada reparto contiene hasta tres chicos.
- Cada jugador juega una carta por chico.
- La carta de fuerza maxima decide el chico.
- Si la fuerza maxima aparece en ambos equipos, el chico queda empatado.
- Cada chico empatado concede un chico a cada equipo.
- Un empate no inicia otro reparto: se continua con las cartas disponibles.
- Gana el reparto el primer equipo que alcanza dos chicos.
- Si ambos alcanzan dos chicos simultaneamente, el reparto termina empatado y
  no se suman chinos.
- El ganador suma el valor vigente del reparto y entonces se reparten cartas.
- Una fuerza maxima empatada nunca se desempata con la segunda carta.
- La jerarquia canonica vive en `ZapitiRules.strength`; tutoriales y bots deben
  coincidir con ella.

## Truco

- Solo existe una negociacion de truco por reparto.
- Mientras esta pendiente se puede aceptar, rechazar o subir alternativamente.
- Tras aceptar o rechazar no se puede volver a cantar en ese reparto.
- En local, el humano decide por su equipo: el companero bot no canta ni sube.
- Los rivales bot si pueden cantar o subir.
- Las restricciones de puntuacion se calculan por equipo segun `TrucoRules`.

## Criterios de implementacion

- Mantener clases pequenas, nombres claros y estados explicitos.
- Preferir modelos inmutables cuando sea razonable.
- Anadir tests al cambiar una regla.
- No modificar callbacks, sincronizacion o reglas al hacer cambios visuales.
- No introducir gestores de estado o dependencias sin una necesidad concreta.
- Conservar la orientacion horizontal y el responsive de la partida.

## Validacion

Antes de cerrar cambios funcionales o visuales, ejecutar:

```text
flutter analyze
flutter test
```
