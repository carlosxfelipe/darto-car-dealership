# 10 — Estrutura de Projeto

---

## Gerada pelo CLI

```sh
darto create my_api
```

```
my_api/
├── bin/
│   └── server.dart          # Entrypoint — chama createApp() e listen()
├── lib/
│   ├── app.dart             # Monta o app (exporta createApp())
│   ├── config/
│   │   └── env.dart         # Carrega e expõe variáveis de ambiente
│   └── modules/
│       └── user/
│           ├── user_controller.dart   # Handlers de rota
│           ├── user_service.dart      # Lógica de negócio
│           ├── user_repository.dart   # Acesso a dados
│           └── user_routes.dart       # Registra rotas no Router
├── pubspec.yaml
└── .env
```

---

## Padrão recomendado (NestJS-style)

### `bin/server.dart`

```dart
import 'package:my_api/app.dart';
import 'package:darto_env/darto_env.dart';

void main() async {
  DartoEnv.load();
  final app  = createApp();
  final port = DartoEnv.getInt('PORT', 3000);
  await app.listen(port, () => print('Servidor em http://localhost:$port'));
}
```

### `lib/app.dart`

```dart
import 'package:darto/darto.dart';
import 'package:darto/logger.dart';
import 'package:darto/cors.dart';
import 'package:darto_env/darto_env.dart';
import 'modules/users/user_routes.dart';
import 'modules/products/product_routes.dart';

Darto createApp() {
  final app = Darto().basePath('/v1');

  app.use(logger());
  app.mount('/api/*', cors(origin: DartoEnv.maybeGet('ALLOWED_ORIGIN') ?? '*'));

  app.route('/users',    userRoutes);
  app.route('/products', productRoutes);

  app.onError((err, c) => c.internalError({'error': err.message}));
  app.notFound((c) => c.notFound({'error': 'Rota não encontrada: ${c.req.path}'}));

  return app;
}
```

### `lib/config/env.dart`

```dart
import 'package:darto_env/darto_env.dart';

class Env {
  static String get jwtSecret   => DartoEnv.getOrThrow('JWT_SECRET');
  static String get databaseUrl => DartoEnv.getOrThrow('DATABASE_URL');
  static int    get port        => DartoEnv.getInt('PORT', 3000);
  static bool   get debug       => DartoEnv.getBool('DEBUG', false);
}
```

### `lib/modules/users/user_routes.dart`

```dart
import 'package:darto/darto.dart';
import 'user_service.dart';

void userRoutes(Router router) {
  final service = UserService();

  router.get('/', [], (Context c) async {
    final users = await service.getAll();
    return c.ok(users.map((u) => u.toJson()).toList());
  });

  router.post('/', [], (Context c) async {
    final body = await c.req.json();
    final user = await service.create(body['name'] as String);
    return c.created(user.toJson());
  });

  router.get('/:id', [], (Context c) async {
    final user = await service.findById(c.req.param('id')!);
    if (user == null) return c.notFound({'error': 'Não encontrado'});
    return c.ok(user.toJson());
  });

  router.put('/:id', [], (Context c) async {
    final body = await c.req.json();
    final user = await service.update(c.req.param('id')!, body['name'] as String);
    if (user == null) return c.notFound({'error': 'Não encontrado'});
    return c.ok(user.toJson());
  });

  router.delete('/:id', [], (Context c) async {
    await service.delete(c.req.param('id')!);
    return c.noContent();
  });
}
```

### `lib/modules/users/user_service.dart`

```dart
import 'user_model.dart';
import 'user_repository.dart';

class UserService {
  final _repo = UserRepository();

  Future<List<User>> getAll() => _repo.findAll();
  Future<User?> findById(String id) => _repo.findById(id);
  Future<User> create(String name) => _repo.save(User(name: name));
  Future<User?> update(String id, String name) => _repo.update(id, name);
  Future<void> delete(String id) => _repo.delete(id);
}
```

### `lib/modules/users/user_model.dart`

```dart
class User {
  final String id;
  final String name;

  User({String? id, required this.name})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'] as String, name: json['name'] as String);
}
```

---

## `.env` exemplo

```
PORT=3000
JWT_SECRET=troque-isso-em-producao-32chars!!
DATABASE_URL=postgres://user:pass@localhost:5432/mydb
DEBUG=false
ALLOWED_ORIGIN=https://meuapp.com
```

---

## `pubspec.yaml` típico

```yaml
name: my_api
description: Backend com Darto
version: 1.0.0
publish_to: none

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  darto: ^1.2.0
  darto_env: ^1.0.0
  darto_validator: ^1.0.0

dev_dependencies:
  darto_test: ^1.0.0
  test: ^1.24.0
  lints: ^3.0.0
```

---

## Dicas de organização

- **Um módulo por domínio** — `users/`, `products/`, `orders/`, etc.
- **`createApp()` exportável** — facilita testes (veja `09-testing.md`).
- **Rotas via `Router`** — registradas com `app.route('/path', routeFn)`.
- **Env carregado no `main`** — antes de qualquer outra coisa.
- **Middlewares globais no `app.dart`** — logger, CORS, error handler.
- **Middlewares de auth no `app.mount`** — por prefixo de caminho.
