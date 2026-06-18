# 01 — Getting Started

## Instalação

Adicione ao `pubspec.yaml`:

```yaml
dependencies:
  darto: ^1.2.0
```

---

## Quick Start

```dart
import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  app.get('/hello', [], (Context c) => c.ok({'message': 'Hello, Darto!'}));

  app.listen(3000, () => print('Listening on http://localhost:3000'));
}
```

---

## CLI (recomendado)

```sh
# Instalar a CLI globalmente
dart pub global activate darto_cli

# Scaffold de um novo projeto
darto create my_api
cd my_api

# Dev server com hot-reload
darto dev

# Build para produção (gera binário + Dockerfile)
darto build
darto start

# Gerar client Flutter/Dart tipado
darto gen client flutter
darto gen client flutter --output lib/src/api_client.dart --base-url https://api.example.com
```

> Certifique-se de que `~/.pub-cache/bin` está no seu `PATH`.

---

## Criando o app

```dart
final app = Darto();             // trailing slash não-estrito (padrão)
final app = Darto(strict: true); // /users ≠ /users/

// Base path global — prefixa todas as rotas
final app = Darto().basePath('/v1');
app.get('/users', [], handler); // registrado como /v1/users
```

---

## Iniciando e parando o servidor

```dart
// Formas simples
app.listen(3000);
app.listen(3000, () => print('pronto'));

// Controle total: host, HTTPS/TLS, graceful shutdown
await app.serve(port: 8080, host: 'localhost');

// HTTPS com TLS
final ctx = SecurityContext()
  ..useCertificateChain('cert.pem')
  ..usePrivateKey('key.pem');
await app.serve(port: 443, securityContext: ctx);
await app.listenSecure(443, ctx);

// Parar graciosamente
await app.stop();
await app.stop(drainTimeout: Duration(seconds: 5));

// Inspecionar estado
bool running = app.isRunning;
int? port    = app.port;
```

Por padrão, `serve`/`listen` interceptam `SIGINT`/`SIGTERM` e fazem graceful shutdown.
Passe `shutdownSignals: false` para desativar.

---

## Exemplo completo (app real)

```dart
import 'package:darto/darto.dart';
import 'package:darto/cors.dart';
import 'package:darto/logger.dart';
import 'package:darto/jwt.dart';
import 'package:darto/body_limit.dart';

void main() {
  final app = Darto().basePath('/v1');

  // Middlewares globais
  app.use(logger());
  app.mount('/api/*', cors(origin: 'https://myapp.com', credentials: true));

  // Health check (sem auth)
  app.get('/health', [], (Context c) => c.ok({'status': 'ok'}));

  // API protegida por JWT
  final api = app.group('/api');
  api.use(jwt(secret: 'super-secret'));

  api.get('/me', [], (Context c) {
    final payload = c.get<Map<String, dynamic>>('jwtPayload');
    return c.ok({'sub': payload['sub']});
  });

  api.route('/posts')
    .get([], (Context c) async {
      final page = c.req.queryInt('page') ?? 1;
      return c.ok({'page': page, 'posts': []});
    })
    .post([bodyLimit(maxSize: 100 * 1024)], (Context c) async {
      final body = await c.req.json();
      return c.created(body);
    });

  // Tratamento de erros
  app.onError((err, c) => c.internalError({'error': err.message}));
  app.notFound((c) => c.notFound({'error': 'Not found'}));

  app.listen(3000, () => print('Listening on http://localhost:3000'));
}
```

---

## Inspecionar rotas registradas

```dart
import 'package:darto/dev.dart';

showRoutes(app);                          // tabela simples
showRoutes(app, colorize: true, verbose: true); // com cores e contagem de middlewares

// Ou acesse programaticamente
final specs   = app.routes;       // List<RouteSpec> — {method, path}
final entries = app.routeEntries; // List com {method, path, middlewareCount}
```
