# 02 — Routing

## Verbos HTTP

```dart
app.get(path, middlewares, handler);
app.post(path, middlewares, handler);
app.put(path, middlewares, handler);
app.patch(path, middlewares, handler);
app.delete(path, middlewares, handler);
app.head(path, middlewares, handler);
app.options(path, middlewares, handler);

// Todos os verbos
app.all(path, middlewares, handler);

// Múltiplos verbos × múltiplos caminhos
app.on(['GET', 'POST'], ['/a', '/b'], [], handler);
app.on(['PURGE'], ['/cache'], [], handler);
```

> Rotas literais (sem parâmetros/wildcards) são comparadas por string direta — caminho rápido.
> Rotas dinâmicas usam um matcher compilado.

---

## Parâmetros de rota

```dart
// Parâmetro nomeado
app.get('/users/:id', [], (c) => c.ok({'id': c.req.param('id')}));

// Parâmetro opcional
app.get('/posts/:slug?', [], handler);

// Restrição por regex
app.get('/items/:id(\\d+)', [], handler);

// Wildcard nomeado
app.get('/files/*path', [], (c) => c.text(c.req.param('path') ?? ''));

// Wildcard sem nome
app.get('/assets/*', [], handler);
```

### Leitura de parâmetros

```dart
String?       c.req.param('id')        // string
int?          c.req.paramInt('id')      // int
double?       c.req.paramDouble('id')   // double
List<String?> c.req.params()            // todos os valores de parâmetros
```

---

## Query strings

```dart
String?      c.req.query('page')
int?         c.req.queryInt('page')
double?      c.req.queryDouble('amount')
bool         c.req.queryBool('active')  // 'true'/'1'/'yes'/'on' → true
List<String> c.req.queries()            // todos os valores
```

---

## Grupos de rotas — fluent chaining

```dart
app.route('/users')
  .get([], listUsers)
  .post([auth()], createUser)
  .on(['PUT', 'DELETE'], [], handler);
```

## Grupos de rotas — callback builder

```dart
app.route('/users', (r) {
  r.get('/',    [], listUsers);
  r.post('/',   [auth()], createUser);
  r.get('/:id', [], getUser);
  r.delete('/:id', [auth()], deleteUser);
});
```

## Prefix groups (app.group)

```dart
final api = app.group('/api');

api.get('/status', [], (c) => c.ok({'ok': true}));
api.get('/users', [jwtMiddleware], listUsers);

// Grupos aninhados
app.group('/api')
   .group('/v2')
   .get('/ping', (c) => c.text('pong'));
// → GET /api/v2/ping
```

## Router standalone

```dart
Router userRouter() {
  final r = Router();
  r.get('/',    [], listUsers);
  r.post('/',   [], createUser);
  r.get('/:id', [], getUser);
  return r;
}

// Anexar via route()
app.route('/users', userRoutes); // void userRoutes(Router r) { ... }
```

### Exemplo real com Router em módulo separado

```dart
// lib/modules/users/user_routes.dart
void userRoutes(Router router) {
  final service = UserService();

  router.get('/', [], (Context c) async {
    final users = await service.getAllUsers();
    return c.ok(users.map((u) => u.toJson()).toList());
  });

  router.post('/', [], (Context c) async {
    final dto = CreateUserDto.fromJson(await c.req.json());
    final user = await service.createUser(dto);
    return c.created(user.toJson());
  });

  router.get('/:id', [], (Context c) async {
    final user = await service.getUserById(c.req.param('id')!);
    if (user == null) return c.notFound();
    return c.ok(user.toJson());
  });
}

// lib/app.dart
app.route('/users', userRoutes);
```

---

## Render / Layouts (HTML server-side)

### Registrar layout global

```dart
app.use((Context c, Next next) async {
  c.setRender((content, props) => c.html('''
    <!DOCTYPE html>
    <html lang="pt">
      <head>
        <meta charset="UTF-8">
        <title>${props['title'] ?? 'Darto App'}</title>
      </head>
      <body>
        $content
      </body>
    </html>
  '''));
  await next();
});
```

### Usar o layout em handlers

```dart
app.get('/', (Context c) {
  return c.render('<h1>Bem-vindo</h1>', {'title': 'Home'});
});
```

### Override de layout por rota

```dart
app.mount('/admin/*', (Context c, Next next) async {
  c.setRender((html, props) => c.html('''
    <html><body class="admin"><nav>Painel</nav>$html</body></html>
  '''));
  await next();
});
```

---

## View Engine (templates em arquivo)

```yaml
dependencies:
  darto_view: ^1.0.0
```

```dart
import 'package:darto_view/darto_view.dart';

app.use(viewEngine(MustacheEngine(viewsPath: 'views')));

app.get('/', [], (c) => c.render('index', {
  'title': 'Home',
  'items': ['Routing', 'Middleware', 'Validation'],
}));
```

`views/index.mustache`:
```html
<!DOCTYPE html>
<html>
  <head><title>{{title}}</title></head>
  <body>
    <ul>
      {{#items}}<li>{{.}}</li>{{/items}}
    </ul>
  </body>
</html>
```

> Templates são cacheados em memória após o primeiro render.
> Use `app.mount('/admin', viewEngine(...))` para escopo por caminho.

---

## Tratamento de erros

```dart
// Handler global de erro
app.onError((DartoError err, Context c) {
  print(err.message);
  print(err.stackTrace);
  return c.internalError({'error': err.message});
});

// Handler 404 customizado
app.notFound((Context c) {
  return c.notFound({'error': 'Rota não encontrada: ${c.req.path}'});
});
```

`DartoError`:

| Propriedade | Tipo | Descrição |
|---|---|---|
| `cause` | `Object` | O objeto original lançado |
| `stackTrace` | `StackTrace` | Stack trace do ponto do throw |
| `message` | `String` | Atalho para `cause.toString()` |
