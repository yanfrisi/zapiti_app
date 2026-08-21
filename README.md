# Zapiti App

Zapiti es un juego de cartas españolas por parejas. Este repositorio contiene el cliente Flutter con partida local, multijugador y la base de IA para los bots.

## Arranque rápido

```bash
flutter pub get
flutter run
```

La app arranca en horizontal por defecto y carga recursos desde `assets/`.

## Multijugador

La URL del servidor está centralizada en `lib/config/server_config.dart`.

### Producción

Por defecto el cliente usa:

```text
wss://zapiti-server.onrender.com/
```

### Desarrollo local

```bash
flutter run -d chrome --dart-define=USE_LOCAL_SERVER=true
```

URLs locales por defecto:

- Web: `ws://localhost:8080/`
- Android Emulator: `ws://10.0.2.2:8080/`

Si necesitas otra URL local:

```bash
flutter run -d chrome --dart-define=USE_LOCAL_SERVER=true --dart-define=LOCAL_SERVER_URL=ws://IP_LOCAL:8080
```

## IA y simulación

El proyecto ya separa la lógica observable de la simulación pura:

- `ObservableGameState` expone solo información permitida al bot.
- `UniformPossibleDealSampler` genera determinizaciones compatibles.
- `SimulationGameState` representa un mundo simulado concreto.
- `DefaultSimulationGameEngine` aplica cartas y resuelve bazas sobre el estado simulado.
- `MonteCarloCardSelector` evalúa cartas por simulaciones y elige la mejor.
- `MonteCarloDifficultyConfigs` centraliza la potencia por dificultad.

Los bots mantienen un fallback heurístico seguro si la simulación no puede decidir.

## Tests

```bash
flutter test
```

Tests útiles del motor de IA:

```bash
flutter test test/domain/observable_game_state_test.dart test/domain/possible_deal_sampler_test.dart test/domain/simulation_game_engine_test.dart
```

## Análisis estático

```bash
flutter analyze
```

## Benchmark básico de IA

```bash
flutter test test/domain/monte_carlo_benchmark_test.dart
```

## Estructura principal

- `lib/domain/` contiene reglas, simulación y bots.
- `lib/screens/` contiene la UI de juego, menú y setup.
- `lib/services/` contiene red, preferencias y sincronización.
- `assets/` contiene cartas, personajes, audio e idiomas.

## Estado actual

La app incluye:

- reglas de truco con alternancia real;
- `BetState` y sincronización de `stateVersion`;
- señal `Ven a mí`;
- políticas de bots por dificultad;
- determinización de cartas ocultas;
- simulación pura de mano;
- Monte Carlo básico para elección de cartas;
- benchmark reproducible del lado app.

## Pendiente

- cerrar completamente `C:\ESD\zapiti_server`;
- generar APK release y AAB firmado;
- cerrar ajustes finos de fuerza táctica en IA;
- añadir más paridad entre simulación pura y controlador real.
