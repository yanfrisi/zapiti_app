# Zapiti App

Cliente Flutter de Zapiti con modo local y multijugador.

## Ejecutar en local

```bash
flutter pub get
flutter run
```

## Multijugador

La URL del servidor está centralizada en `lib/config/server_config.dart`.

### Producción

Por defecto el cliente usa:

```text
wss://zapiti-server.onrender.com/
```

### Desarrollo local

Arranca el cliente con:

```bash
flutter run -d chrome --dart-define=USE_LOCAL_SERVER=true
```

URLs locales por defecto:

- Web: `ws://localhost:8080/`
- Android Emulator: `ws://10.0.2.2:8080/`

Si necesitas otra URL local, puedes pasarla con:

```bash
flutter run -d chrome --dart-define=USE_LOCAL_SERVER=true --dart-define=LOCAL_SERVER_URL=ws://IP_LOCAL:8080
```

## Estados de conexión

El cliente muestra estados claros mientras conecta al servidor, lo despierta, se reconecta o falla.

Si la conexión se corta en mitad de una partida, el cliente intenta volver a abrir el canal, pero no recupera automáticamente la sala anterior porque el protocolo aún no tiene reanudación de sesión.

## Tests

```bash
flutter test
```
