# Release Notes - 0.2.1

## Notas de versión

### Juego y UI
- Se amplió el tutorial para móvil con una guía mucho más completa sobre cómo se juega Zapiti.
- Se añadió navegación de vuelta en el flujo de selección de personaje y dificultad para un jugador.
- Se corrigió el desbordamiento vertical en la pestaña de práctica del tutorial.

### IA y simulación
- Se introdujo `ObservableGameState` como vista inmutable y limitada a información observable.
- Se añadió `UniformPossibleDealSampler` para generar determinizaciones válidas sin consultar manos ocultas reales.
- Se creó una configuración centralizada por dificultad para la IA Monte Carlo.
- Se añadió un estado de simulación puro, una fábrica de estado y un motor de transiciones compartido.
- Se incorporó un selector Monte Carlo para elegir cartas con fallback heurístico seguro.
- Se ajustó la evaluación para premiar mejor la conservación de fuerza y la coordinación de equipo.

### Integración y validación
- La selección de bots ahora puede usar Monte Carlo en dificultades altas.
- Se añadieron pruebas para el estado observable, el sampler, el motor de simulación y un benchmark básico de IA.
- `flutter analyze` pasa sin issues en el estado actual del trabajo.

### Multijugador y mantenimiento
- Se mantuvieron los ajustes de conexión y el flujo de multijugador existentes.
- Se actualizó el `README` para servir mejor como portada técnica del repositorio.

## Texto para Google Play Store

Novedades de esta versión:

- Tutorial más claro para aprender Zapiti desde cero.
- Mejoras en la práctica para móvil.
- Botón de volver en la selección de personaje y dificultad.
- IA de bots mejorada con simulación Monte Carlo.
- Correcciones y ajustes de rendimiento.

## Notas
- La IA sigue conservando un fallback heurístico por seguridad.
- ISMCTS todavía no está activado.
- La simulación pura y el Monte Carlo están preparados para seguir creciendo sin duplicar reglas.
