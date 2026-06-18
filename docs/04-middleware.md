# 04 — Middleware

## Escopo de aplicação

```dart
// Global — todas as rotas
app.use(logger());
app.use(cors());

// Scoped por caminho
app.mount('/api/*', jwtMiddleware);
app.mount('/api/*', rateLimiter());

// Nível de rota
app.get('/admin', [requireAdmin()], handler);
app.post('/upload', [bodyLimit(maxSize: 5 * 1024 * 1024)], handler);
```

## Escrevendo um middleware

```dart
Middleware timer() => (Context c, Next next) async {
  final sw = Stopwatch()..start();
  await next();
  print('${c.req.method} ${c.req.path}  ${sw.elapsedMilliseconds}ms');
};
```

## Short-circuit (rejeitar sem chamar `next`)

```dart
Middleware requireAdmin() => (Context c, Next next) async {
  if (c.user?['role'] != 'admin') {
    c.forbidden({'error': 'Apenas admins'});
    return; // pipeline para aqui
  }
  await next();
};
```

---

## Built-in Middlewares

### Logger

```dart
import 'package:darto/logger.dart';

app.use(logger());                                  // imprime no stdout
app.use(logger((msg, [rest]) => myLog.info(msg)));  // printer customizado
```

### Request ID

```dart
import 'package:darto/request_id.dart';

app.use(requestId());                          // X-Request-Id (UUID v4)
app.use(requestId(headerName: 'X-Trace-Id')); // header customizado

app.get('/', [], (c) => c.ok({'id': requestIdOf(c)}));
```

Honra o header de entrada se presente; caso contrário, gera UUID v4.

### ETag

```dart
import 'package:darto/etag.dart';

app.use(etag());            // validador forte
app.use(etag(weak: true));  // validador fraco: W/"…"
```

Faz hash da resposta, define `ETag`, e retorna `304 Not Modified` quando `If-None-Match` bate.

### CORS

```dart
import 'package:darto/cors.dart';

app.mount('/api/*', cors()); // permissivo (origin: *)

app.mount('/api/*', cors(
  origin: 'https://example.com',
  allowMethods: ['GET', 'POST', 'DELETE'],
  allowHeaders: ['Content-Type', 'Authorization'],
  exposeHeaders: ['X-Total-Count'],
  maxAge: 600,
  credentials: true,
));

// Origin dinâmica
app.use(cors(
  originFn: (origin) => origin.endsWith('.example.com') ? origin : '*',
));

// Métodos dinâmicos por origin
app.use(cors(
  allowMethodsFn: (origin, c) =>
      origin == 'https://admin.example.com'
          ? ['GET', 'POST', 'DELETE']
          : ['GET'],
));
```

### Compress

```dart
import 'package:darto/compress.dart';

app.use(compress());

app.use(compress(
  encoding: 'gzip',  // 'gzip' (padrão) ou 'deflate'
  threshold: 1024,   // mínimo de bytes para comprimir (padrão: 1024)
));
```

### CSRF

```dart
import 'package:darto/csrf.dart';

app.use(csrf(origin: 'https://example.com'));
app.use(csrf(origins: ['https://app.com', 'https://admin.app.com']));
app.use(csrf(secFetchSite: 'same-origin'));
app.use(csrf(originFn: (origin) => origin.endsWith('.myapp.com')));
```

### Body Limit

```dart
import 'package:darto/body_limit.dart';

app.post('/upload', [
  bodyLimit(maxSize: 5 * 1024 * 1024), // 5 MB
], handler);

app.post('/upload', [
  bodyLimit(
    maxSize: 50 * 1024,
    onError: (c) => c.status(413).text('Payload muito grande'),
  ),
], handler);
```

### Rate Limit

```dart
import 'package:darto/rate_limit.dart';

// 100 requisições/minuto por IP (em memória)
app.use(rateLimit(max: 100, window: Duration(minutes: 1)));

// Por usuário, skip em health check, rejeição customizada
app.mount('/api/*', rateLimit(
  max: 20,
  keyGenerator: (c) => c.user?['id'] ?? c.req.ip,
  skip: (c) => c.req.path == '/api/health',
  onLimitExceeded: (c) => c.status(429).json({'error': 'devagar'}),
));
```

Emite headers IETF draft: `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`, `Retry-After`.

### Health Check

```dart
import 'package:darto/health.dart';

// Liveness — 200 enquanto o processo estiver rodando
app.get('/healthz', [], health());

// Readiness — 503 até as dependências estarem disponíveis
app.get('/readyz', [], health(
  checks: {'db': () => db.ping(), 'cache': () => redis.ping()},
  info: () => {'version': '1.2.0'},
));
```

Retorna `200 {"status":"ok"}` quando todas as checks passam, ou `503` com as que falharam.

### Cache (HTTP)

```dart
import 'package:darto/cache.dart';

app.get('*', cache(
  cacheName: 'my-app',
  cacheControl: 'max-age=3600',
));

app.get('/api/*', cache(
  cacheName: 'api-cache',
  wait: true,
  cacheableStatusCodes: [200, 203],
  keyGenerator: (c) => '${c.req.method}:${c.req.path}',
));
```

---

## Auth Middlewares

### JWT

```dart
import 'package:darto/jwt.dart';

app.mount('/api/*', jwt(secret: 'mySecret'));

app.mount('/api/*', jwt(
  secret: env.jwtSecret,
  alg: 'HS512',
  cookie: 'access_token',      // ler do cookie ao invés do header
  headerName: 'authorization',
  verifyOptions: VerifyOptions(iss: 'my-app', exp: true, nbf: true, iat: true),
));

// Payload disponível no handler:
final payload = c.get<Map<String, dynamic>>('jwtPayload');
```

### Optional JWT

Como `jwt()` mas nunca rejeita — popula `c.user` quando válido, senão deixa passar.

```dart
app.mount('/feed', optionalJwt(secret: env.secret));

app.get('/feed', (c) {
  final user = c.user; // null para anônimo
  return c.ok({'personalised': user != null});
});
```

### Basic Auth

```dart
import 'package:darto/basic_auth.dart';

app.mount('/admin/*', basicAuth(username: 'admin', password: 'secret'));

app.mount('/admin/*', basicAuth(
  verifyUser: (user, pass, c) => user == 'admin' && pass == env.adminPass,
  onAuthSuccess: (c, username) => c.set('adminUser', username),
  realm: 'Admin Panel',
));
```

### Bearer Auth

```dart
import 'package:darto/bearer_auth.dart';

app.mount('/api/*', bearerAuth(token: 'my-api-key'));
app.mount('/api/*', bearerAuth(token: ['key1', 'key2']));

app.mount('/api/*', bearerAuth(
  verifyToken: (token, c) async => await db.isValidApiKey(token),
));
```

### API Key Auth

```dart
import 'package:darto/api_key_auth.dart';

// Header padrão: x-api-key
app.mount('/api/*', apiKeyAuth(validate: (key) => key == env.apiKey));

// Header customizado
app.mount('/webhooks', apiKeyAuth(
  header: 'x-webhook-secret',
  validate: (key) => key == env.webhookSecret,
));
```

### Require Roles (RBAC)

Verifica que o usuário autenticado tem **todos** os roles especificados. Lê `c.user['roles']` como `List<String>`.

```dart
import 'package:darto/require_roles.dart';

app.delete('/posts/:id', [
  jwt(secret: env.secret),
  requireRoles(['admin']),
], deleteHandler);

// Múltiplos roles — usuário precisa ter TODOS
app.get('/reports', [
  jwt(secret: env.secret),
  requireRoles(['admin', 'auditor']),
], handler);
```

---

## Combinando Middlewares

```dart
import 'package:darto/combine.dart';

// some — primeiro middleware que passa vence (lógica OR)
app.mount('/api/*', some(jwtMiddleware, apiKeyMiddleware));

// every — todos devem passar (lógica AND)
app.mount('/admin/*', every(jwtMiddleware, requireAdmin()));

// except — pular middleware para paths/condições específicas
app.use(except('/health', logger()));
app.use(except(['/health', '/metrics'], rateLimiter()));
app.use(except((c) => c.req.method == 'OPTIONS', auth()));
```

---

## Proxy reverso

```dart
import 'package:darto/proxy.dart';

app.all('/api/users/*', [], (Context c) =>
    proxy(c, 'https://backend.com${c.req.path}'));

// Com override de headers
app.get('/data', [], (Context c) async =>
    proxy(c, 'https://external.com/data',
        options: ProxyOptions(
            headers: {
                'Authorization': 'Bearer INTERNAL_TOKEN', // substituir
                'Cookie': null,                            // remover
            },
        ),
    ),
);

// Desabilitar forwarding automático
app.post('/webhook', [], (Context c) async =>
    proxy(c, 'https://service.com/hook',
        options: ProxyOptions(
            forwardHeaders: false,
            forwardBody: false,
            headers: {'X-Source': 'darto'},
        ),
    ),
);
```

O `proxy` lida automaticamente com: remoção de headers hop-by-hop, gerenciamento de `Accept-Encoding`, remoção de `Content-Encoding`/`Content-Length` da resposta upstream.
