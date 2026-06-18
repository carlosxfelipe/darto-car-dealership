# 06 — Autenticação

---

## JWT Helpers

```dart
import 'package:darto/jwt.dart';

// Construir payload
final payload = JwtPayload(
  sub: 'user123',
  exp: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300, // +5 min
  extra: {'role': 'admin', 'tenantId': 'acme'},
);

// Assinar
final token = await sign(payload, 'mySecret');
final token = await sign(payload, 'mySecret', alg: 'HS512');
// também aceita Map:
final token = await sign({'sub': 'u1', 'exp': ...}, 'secret');

// Verificar (lança JwtException em caso de falha)
try {
  final claims = await verify(token, 'mySecret');
  print(claims['sub']); // 'user123'
} on JwtException catch (e) {
  print(e.message); // 'Token expired', 'Invalid signature', etc.
}

// Decodificar sem verificar
final [header, payload] = decode(token);
print(header['alg']);  // 'HS256'
print(payload['sub']); // 'user123'
```

**Campos de `JwtPayload`:**

| Campo | Tipo | Descrição |
|---|---|---|
| `sub` | `String?` | Subject |
| `iss` | `String?` | Issuer |
| `aud` | `String?` | Audience |
| `exp` | `int?` | Expiração (Unix seconds) |
| `nbf` | `int?` | Not-before (Unix seconds) |
| `iat` | `int?` | Issued-at (Unix seconds) |
| `jti` | `String?` | JWT ID |
| `extra` | `Map<String, dynamic>` | Claims customizados |

**Algoritmos suportados:** `HS256` (padrão), `HS384`, `HS512`.

---

## Fluxo JWT completo (login + rotas protegidas)

```dart
import 'package:darto/darto.dart';
import 'package:darto/jwt.dart';
import 'package:darto/require_roles.dart';

const _secret = 'troque-isso-em-producao';

final _users = [
  {'id': 1, 'email': 'alice@example.com', 'password': 'pass123', 'roles': ['user']},
  {'id': 2, 'email': 'admin@example.com', 'password': 'admin123', 'roles': ['user', 'admin']},
];

void main() {
  final app = Darto();

  // Login — emite JWT
  app.post('/login', [], (Context c) async {
    final body  = await c.req.json();
    final email = body['email'] as String?;
    final pass  = body['password'] as String?;

    final user = _users.firstWhere(
      (u) => u['email'] == email && u['password'] == pass,
      orElse: () => {},
    );

    if (user.isEmpty) return c.unauthorized({'error': 'Credenciais inválidas'});

    final exp   = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    final token = await sign(
      {'id': user['id'], 'email': user['email'], 'roles': user['roles'], 'exp': exp},
      _secret,
    );

    return c.ok({'token': token});
  });

  // Rota protegida — requer JWT válido
  app.get('/me', [jwt(secret: _secret)], (Context c) {
    return c.ok({'user': c.user});
  });

  // Rota protegida — requer JWT + role admin
  app.get('/admin', [jwt(secret: _secret), requireRoles(['admin'])], (Context c) {
    return c.ok({'message': 'Área admin', 'user': c.user});
  });

  app.listen(3000);
}
```

---

## Sessões baseadas em cookie

```dart
import 'package:darto/session.dart';

app.use(sessionMiddleware(
  secret: 'pelo-menos-32-chars-de-segredo!!',
  duration: 60 * 30,
  cookieName: 'darto.session',
));

app.post('/login', [], (c) async {
  final body = await c.req.json();
  await sessionContext(c).update({'userId': body['id'], 'role': 'user'});
  return c.ok({'message': 'logado'});
});

app.get('/me', [], (c) {
  final data = sessionContext(c).get();
  if (data == null) return c.unauthorized({'error': 'sem sessão'});
  return c.ok(data);
});

app.post('/logout', [], (c) {
  sessionContext(c).delete();
  return c.noContent();
});
```

---

## `darto_auth` — Hash de senha + Session Auth + OAuth

```yaml
dependencies:
  darto_auth: ^1.0.0
```

### Hash de senha (PBKDF2)

```dart
import 'package:darto_auth/darto_auth.dart';

final hash = hashPassword('s3cret');          // armazenar isso
final ok   = verifyPassword('s3cret', hash);  // true

// Configurar work factor:
const hasher = PasswordHasher(iterations: 200000);
final h = hasher.hash('s3cret');
```

### Session Auth (login + guard)

```dart
import 'package:darto/darto.dart';
import 'package:darto/session.dart';
import 'package:darto_auth/darto_auth.dart';

app.use(sessionMiddleware(secret: env.sessionSecret));

app.post('/login', [], (c) async {
  final body = await c.req.json();
  final user = await users.findByEmail(body['email']);

  if (user == null || !verifyPassword(body['password'], user.hash)) {
    return c.unauthorized({'error': 'credenciais inválidas'});
  }

  await signIn(c, {'id': user.id, 'role': user.role});
  return c.ok({'ok': true});
});

// authGuard() — retorna 401 se não autenticado; define c.user se autenticado
app.get('/me',      [authGuard()], (c) => c.ok(authUser(c)));
app.post('/logout', [], (c) { signOut(c); return c.noContent(); });
```

| Símbolo | Descrição |
|---|---|
| `signIn(c, user)` | Armazenar usuário na sessão |
| `signOut(c)` | Limpar sessão |
| `authUser(c)` | Usuário da sessão ou `null` |
| `authGuard({onUnauthorized})` | Middleware — 401 se não autenticado |

---

### OAuth 2.0 / OpenID Connect

```dart
import 'package:darto_auth/darto_auth.dart';

// Google (OIDC com discovery)
final google = await OAuthProvider.google(
  clientId: env.googleClientId,
  clientSecret: env.googleClientSecret,
  redirectUri: 'http://localhost:3000/auth/google/callback',
);

app.use(sessionMiddleware(secret: env.sessionSecret));

google.attach(app, '/auth/google', onSignIn: (c, user) async {
  await signIn(c, {'id': user.id, 'email': user.email, 'name': user.name});
  return c.redirect('/');
});
// Registra: GET /auth/google → redireciona para Google
//           GET /auth/google/callback → troca código, decodifica id_token, chama onSignIn

// GitHub (OAuth2)
final github = OAuthProvider.github(
  clientId: env.githubClientId,
  clientSecret: env.githubClientSecret,
  redirectUri: 'http://localhost:3000/auth/github/callback',
);

github.attach(app, '/auth/github', onSignIn: (c, user) async {
  await signIn(c, {'id': user.id, 'email': user.email});
  return c.redirect('/');
});

// Provider genérico (qualquer OAuth2/OIDC)
final azure = OAuthProvider(
  authorizeUrl: 'https://login.microsoftonline.com/<tenant>/oauth2/v2.0/authorize',
  tokenUrl:     'https://login.microsoftonline.com/<tenant>/oauth2/v2.0/token',
  userInfoUrl:  'https://graph.microsoft.com/oidc/userinfo',
  clientId: env.azureClientId,
  clientSecret: env.azureClientSecret,
  redirectUri: '...',
  scopes: ['openid', 'email', 'profile'],
  isOidc: true,
);
```

`OAuthUser` — perfil normalizado: `(id, email, name, picture, raw)`.
