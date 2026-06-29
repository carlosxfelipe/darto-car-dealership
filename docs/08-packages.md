# 08 — Pacotes do Ecossistema

---

## `darto_env` — Carregador de `.env`

```yaml
dependencies:
  darto_env: ^1.0.0
```

```dart
import 'package:darto_env/darto_env.dart';

// Chamar uma vez no início
DartoEnv.load();
// DartoEnv.load('.env.production'); // arquivo customizado

final port   = DartoEnv.getInt('PORT', 3000);
final secret = DartoEnv.get('JWT_SECRET');        // lança se ausente
final debug  = DartoEnv.getBool('DEBUG', false);
final opt    = DartoEnv.maybeGet('OPTIONAL');     // String? — null se não definido
final all    = DartoEnv.all();                    // Map<String, String>
```

`.env`:
```
PORT=3000
JWT_SECRET=supersecret
DEBUG=true
```

> Variáveis de `Platform.environment` têm prioridade sobre os valores do `.env`.

---

## `darto_static` — Arquivos Estáticos

```yaml
dependencies:
  darto_static: ^1.0.0
```

```dart
import 'package:darto_static/darto_static.dart';

// Servir arquivos de ./public em /public/*
app.mount('/public/*', serveStatic('public'));

// URL prefix diferente do nome do diretório
app.mount('/assets/*', serveStatic('dist', urlPrefix: '/assets'));
```

- Path traversal protection embutida
- MIME types detectados automaticamente
- Passa para `next()` se arquivo não encontrado

---

## `darto_inject` — Injeção de Dependência

```yaml
dependencies:
  darto_inject: ^1.0.0
```

```dart
import 'package:darto_inject/darto_inject.dart';

class UserService {
  List<Map<String, dynamic>> list() => [...];
  Map<String, dynamic>? find(int id) => null;
}

// Escopo app — instância única compartilhada por todas as requisições
final userServiceProvider = Provider<UserService>((di) => UserService());

// Escopo request — recriado por requisição
final requestIdProvider = Provider<String>(
  (di) => di.read(contextProvider).req.header('x-request-id') ?? 'none',
  scope: Scope.request,
);

void main() async {
  final di = Di(providers: [userServiceProvider, requestIdProvider]);
  await di.warmup(); // aquece singletons do escopo app

  final app = Darto()..use(di.middleware());

  app.get('/users', [], (Context c) {
    final svc = c.read(userServiceProvider); // mesma instância sempre
    return c.ok(svc.list());
  });

  app.get('/users/:id', [], (Context c) {
    final user = c.read(userServiceProvider).find(c.req.paramInt('id') ?? 0);
    return user == null ? c.notFound({'error': 'não encontrado'}) : c.ok(user);
  });

  app.get('/whoami', [], (Context c) {
    return c.ok({'requestId': c.read(requestIdProvider)});
  });

  await app.listen(3000);
}
```

---

## `darto_cache` — Cache (Memory / Redis)

```yaml
dependencies:
  darto_cache: ^1.0.0
```

```dart
import 'package:darto_cache/darto_cache.dart';

// In-process (MemoryCache com LRU/TTL)
final Cache cache = MemoryCache(maxEntries: 1000);

// Redis (requer servidor Redis)
final Cache cache = await RedisCache.connect(host: 'localhost', prefix: 'app:');

// remember() — retorna do cache se existir; caso contrário executa o builder e armazena
app.get('/users/:id', [], (Context c) async {
  final id   = c.req.paramInt('id') ?? 0;
  final user = await cache.remember<Map<String, dynamic>>(
    'user:$id',
    ttl: const Duration(seconds: 10),
    builder: () => fetchUserFromDb(id),
  );
  return c.ok(user);
});

// Operações manuais
await cache.set('key', value, ttl: Duration(minutes: 5));
final value = await cache.get<Map<String, dynamic>>('key');
await cache.delete('key');
await cache.clear();
```

---

## `darto_rate_limit` — Rate Limit Distribuído (Redis)

```yaml
dependencies:
  darto_rate_limit: ^1.0.0
```

```dart
import 'package:darto_rate_limit/darto_rate_limit.dart';

// Store Redis para uso distribuído/multi-processo
final store = await RedisRateLimitStore.connect(host: 'localhost');

app.use(rateLimit(
  max: 100,
  window: Duration(minutes: 1),
  store: store,
));
```

O `rateLimit()` padrão do core usa `MemoryRateLimitStore` (process-local).
Implemente `RateLimitStore` para backend customizado.

---

## `darto_mailer` — Envio de E-mail

```yaml
dependencies:
  darto_mailer: ^1.0.0
```

```dart
import 'package:darto_mailer/darto_mailer.dart';

// ConsoleTransport — imprime em vez de enviar (ótimo para dev)
final mailer = Mailer(
  from: 'no-reply@example.com',
  transport: ConsoleTransport(),
);

// SMTP para produção
final mailer = Mailer(
  from: 'no-reply@example.com',
  transport: SmtpTransport(
    host: 'smtp.example.com',
    port: 587,
    username: env.smtpUser,
    password: env.smtpPass,
    security: SmtpSecurity.starttls,
  ),
);

// Enviar e-mail
await mailer.send(Message(
  to: 'user@example.com',
  subject: 'Bem-vindo!',
  text: 'Obrigado por se cadastrar.',
  html: '<h1>Bem-vindo!</h1><p>Obrigado por se cadastrar.</p>',
));

// Em um handler
app.post('/signup', [], (Context c) async {
  final body  = await c.req.json();
  final email = body['email'] as String;

  await mailer.send(Message(
    to: email,
    subject: 'Bem-vindo!',
    text: 'Obrigado por se cadastrar.',
    html: '<h1>Bem-vindo!</h1>',
  ));

  return c.created({'email': email});
});
```

> Em produção, passe o envio para `darto_jobs` para que um SMTP lento não bloqueie a resposta.

---

## `darto_jobs` — Background Jobs

```yaml
dependencies:
  darto_jobs: ^1.0.0
```

```dart
import 'package:darto_jobs/darto_jobs.dart';

// In-process store
final queue = JobQueue(store: MemoryJobStore());

// Redis store para durabilidade + múltiplos workers
// final queue = JobQueue(store: await RedisJobStore.connect(host: 'localhost'));

// Registrar handler — lança → retry com backoff exponencial;
// após maxAttempts o job vai para dead-letter e onFailed dispara
queue.handle('send-welcome', (job) async {
  final email = job.data['email'] as String;
  print('tentativa ${job.attempts}');
  await mailer.send(Message(to: email, subject: 'Bem-vindo!', text: '...'));
}, maxAttempts: 3);

queue.onFailed((job, error, _) => print('${job.name} desistiu: $error'));

// Iniciar worker no mesmo processo (produção: processo separado com `dart run`)
queue.work(concurrency: 2);

// Enfileirar job (responde imediatamente, e-mail vai em background)
app.post('/signup', [], (Context c) async {
  final body = await c.req.json();
  final id   = await queue.add('send-welcome', {'email': body['email']});
  return c.created({'queued': id});
});

// Agendar job com delay
app.post('/remind', [], (Context c) async {
  final body = await c.req.json();
  await queue.add('send-welcome', {'email': body['email']},
      delay: const Duration(seconds: 5));
  return c.status(202).json({'scheduled': true});
});

// Estatísticas
app.get('/stats', [], (Context c) async =>
    c.ok((await queue.store.stats()).toString()));
```

---

## `darto_zard_openapi` — OpenAPI 3.1 + Validação com Zard (Recomendado)

> **Nova integração!** Valide as requisições e gere a documentação Swagger/Scalar a partir da mesma fonte de verdade (Single Source of Truth), inspirado no `zod-openapi` do Hono.
> [Link no pub.dev](https://pub.dev/packages/darto_zard_openapi)

```yaml
dependencies:
  darto_zard_openapi: ^1.0.0
```

```dart
import 'package:darto_zard_openapi/darto_zard_openapi.dart';

final app = Darto();
final api = OpenAPIDarto(app);

// 1. Defina o schema uma única vez (Type-safe + Metadados da Doc)
final userSchema = z.map({
  'name': z.string().min(1).openapi(example: 'Ada Lovelace', description: 'Nome completo'),
  'age': z.int().min(0).max(150),
}).openapiSchema('User'); // openapiSchema registra o componente reutilizável

// 2. Crie o contrato da rota de forma desacoplada
final getUser = createRoute(
  method: 'get',
  path: '/users/:id',
  summary: 'Buscar usuário',
  tags: ['Users'],
  request: Req(params: z.map({'id': z.string().uuid()}).openapiSchema()),
  responses: [
    Res(200, 'Usuário encontrado', body: userSchema),
    Res(404, 'Não encontrado'),
  ],
);

// 3. Acople o contrato, middlewares e o handler
api.openapi(getUser, [], (c) {
  // c.req.valid retorna os dados garantidamente validados
  final params = c.req.valid<Map<String, dynamic>>('param');
  final id = params['id'];
  
  return c.ok({'name': 'Ada Lovelace', 'age': 28});
});

// 4. Monta GET /openapi.json (spec) e GET /docs (Scalar UI embutido)
api.doc('/openapi.json', info: Info(title: 'Users API', version: '1.0.0'));
app.get('/docs', [], scalarUI(url: '/openapi.json'));

await app.listen(3000, () {
  print('spec → http://localhost:3000/openapi.json');
  print('docs → http://localhost:3000/docs');
});
```

---

## `darto_logger` — Logger Estruturado

```yaml
dependencies:
  darto_logger: ^1.0.0
```

```dart
import 'package:darto_logger/darto_logger.dart';

final logger = DartoLogger(name: 'my-app');

logger.info('Servidor iniciado');
logger.warning('Algo suspeito', {'path': '/api/secret'});
logger.error('Falha ao conectar', error, stackTrace);

// Como middleware de request
app.use(requestLogger(logger));
```

---

## `darto_view` — Template Engine

```yaml
dependencies:
  darto_view: ^1.0.0
```

```dart
import 'package:darto_view/darto_view.dart';

// Mustache
app.use(viewEngine(MustacheEngine(viewsPath: 'views')));

app.get('/', [], (c) => c.render('index', {
  'title': 'Home',
  'items': ['Routing', 'Middleware'],
}));
```

- Templates cacheados em memória após o primeiro render
- Implemente `TemplateEngine` para engines customizadas
- Use `app.mount('/admin', viewEngine(...))` para escopo por caminho
