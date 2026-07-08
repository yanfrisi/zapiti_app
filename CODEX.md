# Instrucciones para Codex

## Contexto

Este repositorio es un prototipo inicial de un juego de cartas llamado Zápiti.

El usuario sabe programar, principalmente en Java/backend, pero está empezando con Flutter y desarrollo mobile.

El proyecto debe mantenerse simple, claro y progresivo.

## Prioridad técnica

La prioridad absoluta es construir primero el dominio del juego, no una UI bonita.

El código debe ser fácil de leer, con clases pequeñas y tests.

## Arquitectura obligatoria

Mantener esta separación:

- `lib/domain`: reglas, modelos y lógica pura.
- `lib/screens`: pantallas Flutter.
- `test/domain`: tests unitarios de reglas.

No meter lógica de reglas dentro de widgets.

## Estilo de implementación

Preferir:

- Código simple.
- Nombres claros.
- Pocas abstracciones.
- Tests antes de ampliar reglas.
- Modelos inmutables cuando sea razonable.
- Errores explícitos si el estado no tiene sentido.

Evitar:

- Arquitecturas grandes.
- Riverpod, Bloc, Provider o Redux por ahora.
- Firebase.
- Backend.
- Online.
- Animaciones.
- Assets gráficos.
- Refactors innecesarios.

## Estado actual del dominio

Ya existen:

- `SpanishCard`
- `Suit`
- `ZapitiRules`
- `Player`
- `PlayedCard`
- `RoundRules`
- `RoundResult`

`ZapitiRules.strength` define una jerarquía inicial de cartas.

`RoundRules.resolveRound` decide qué jugador gana una ronda según la carta más fuerte.

## Próxima tarea recomendada

Implementar `HandRules`.

### Objetivo

Dadas varias rondas jugadas, determinar qué equipo gana una mano.

### Restricción

No implementar todavía todas las reglas especiales de empate si no están claras.

Primero crear una versión explícita y testeada con estas reglas provisionales:

1. Una mano puede tener hasta 3 rondas.
2. Gana la mano el primer equipo que gane 2 rondas.
3. Si no hay ganador claro, lanzar error o devolver resultado pendiente.

### Archivos sugeridos

Crear:

```text
lib/domain/hand_result.dart
lib/domain/hand_rules.dart
test/domain/hand_rules_test.dart
```

### Modelo sugerido

```dart
class HandResult {
  final int winningTeamId;
  final int roundsWon;
}
```

### Tests mínimos

Crear tests para:

1. Equipo 1 gana dos rondas y gana la mano.
2. Equipo 2 gana dos rondas y gana la mano.
3. Una sola ronda no debería cerrar la mano.
4. Lista vacía de rondas debería fallar explícitamente.

## Importante

No cambiar el proyecto a una arquitectura compleja.

No añadir dependencias salvo que sean estrictamente necesarias.

No trabajar todavía en diseño visual.

No crear assets.

No añadir online.

El objetivo es que el usuario aprenda construyendo el juego paso a paso.
