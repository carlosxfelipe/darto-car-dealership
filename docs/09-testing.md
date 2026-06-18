# 09 — Testes (`darto_test`)

Cliente de testes ergonômico — estilo supertest. Inicia o app em uma porta efêmera e expõe uma API fluente para assertions.

```yaml
dev_dependencies:
  darto_test: ^1.0.0
  test: ^1.0.0
```

---

## Padrão recomendado

Separe a construção do app do `main()` para que os testes possam importar o app sem iniciá-lo.

```dart
// lib/app.dart
import 'package:darto/darto.dart';

Darto buildApp() {
  final db = <int, Map<String, dynamic>>{};
  var nextId = 1;

  final app = Darto();

  app.use((c, next) async {
    c.header('X-Powered-By', 'Darto');
    await next();
  });

  app.get('/users', [], (Context c) => c.ok(db.values.toList()));

  app.post('/users', [], (Context c) async {
    final body = await c.req.json();
    final user = {'id': nextId, 'name': body['name']};
    db[nextId++] = user;
    return c.created(user);
  });

  app.get('/users/:id', [], (Context c) {
    final id   = c.req.paramInt('id');
    final user = db[id];
    if (user == null) return c.notFound({'error': 'não encontrado'});
    return c.ok(user);
  });

  app.put('/users/:id', [], (Context c) async {
    final id = c.req.paramInt('id');
    if (!db.containsKey(id)) return c.notFound({'error': 'não encontrado'});
    final body = await c.req.json();
    db[id!] = {'id': id, 'name': body['name']};
    return c.ok(db[id]!);
  });

  app.delete('/users/:id', [], (Context c) {
    db.remove(c.req.paramInt('id'));
    return c.noContent();
  });

  return app;
}
```

---

## Escrevendo testes

```dart
// test/app_test.dart
import 'package:darto_test/darto_test.dart';
import 'package:my_app/app.dart';
import 'package:test/test.dart';

void main() {
  late TestClient client;

  // App fresco por grupo — sem estado compartilhado entre grupos
  setUp(() async => client = await TestClient.create(buildApp()));
  tearDown(() => client.close());

  group('GET /users', () {
    test('retorna lista vazia no app novo', () async {
      final res = await client.get('/users');
      expect(res.statusCode, 200);
      expect(res.json, isEmpty);
    });

    test('lista usuários após criação', () async {
      await client.post('/users', json: {'name': 'Alice'});
      await client.post('/users', json: {'name': 'Bob'});

      final res = await client.get('/users');
      expect(res.statusCode, 200);
      expect(res.json, hasLength(2));
    });
  });

  group('POST /users', () {
    test('cria usuário e retorna 201', () async {
      final res = await client.post('/users', json: {'name': 'Alice'});
      expect(res.statusCode, 201);
      expect(res.json['name'], 'Alice');
      expect(res.json['id'], isNotNull);
    });
  });

  group('GET /users/:id', () {
    test('retorna usuário quando encontrado', () async {
      final created = await client.post('/users', json: {'name': 'Alice'});
      final id      = created.json['id'];

      final res = await client.get('/users/$id');
      expect(res.statusCode, 200);
      expect(res.json['name'], 'Alice');
    });

    test('retorna 404 para id desconhecido', () async {
      final res = await client.get('/users/999');
      expect(res.statusCode, 404);
      expect(res.json['error'], 'não encontrado');
    });
  });

  group('PUT /users/:id', () {
    test('atualiza o nome do usuário', () async {
      final created = await client.post('/users', json: {'name': 'Alice'});
      final id      = created.json['id'];

      final res = await client.put('/users/$id', json: {'name': 'Alicia'});
      expect(res.statusCode, 200);
      expect(res.json['name'], 'Alicia');
    });
  });

  group('DELETE /users/:id', () {
    test('remove usuário e retorna 204', () async {
      final created = await client.post('/users', json: {'name': 'Alice'});
      final id      = created.json['id'];

      final del = await client.delete('/users/$id');
      expect(del.statusCode, 204);

      final get = await client.get('/users/$id');
      expect(get.statusCode, 404);
    });
  });

  group('middleware', () {
    test('toda resposta tem header X-Powered-By', () async {
      final res = await client.get('/users');
      expect(res.header('x-powered-by'), 'Darto');
    });
  });
}
```

---

## API do `TestClient`

```dart
// Criar — inicia o app em porta efêmera
final client = await TestClient.create(buildApp());

// Métodos HTTP
final res = await client.get('/path');
final res = await client.post('/path', json: {'key': 'value'});
final res = await client.put('/path', json: {'key': 'value'});
final res = await client.patch('/path', json: {'key': 'value'});
final res = await client.delete('/path');

// Com headers customizados
final res = await client.get('/protected',
    headers: {'Authorization': 'Bearer $token'});

// Fechar após os testes
client.close();
```

## API da `TestResponse`

```dart
res.statusCode           // int
res.json                 // dynamic (Map ou List decodificado)
res.text                 // String (body como texto)
res.header('nome')       // String? (header da resposta)
res.headers              // Map<String, String>
```

---

## Executar testes

```sh
dart test
dart test test/app_test.dart
dart test --reporter expanded
```
