# 05 — Validação

Darto oferece duas abordagens para validação: `zValidator` (automático) e `validator()` (controle total).

---

## `zValidator` — via `darto_validator`

```yaml
dependencies:
  darto_validator: ^1.0.0
```

```dart
import 'package:darto/darto.dart';
import 'package:darto_validator/darto_validator.dart';

final userSchema = z.map({
  'name':  z.string().min(1),
  'email': z.string().email(),
  'age':   z.int().min(0).max(150),
});

// Valida JSON body — handler só executa se o schema passar
app.post('/users', [zValidator('json', userSchema)], (c) {
  final data = c.req.valid<Map<String, dynamic>>('json');
  return c.created({'user': data});
});

// Query params
app.get('/search', [zValidator('query', z.map({'q': z.string().min(1)}))], (c) {
  final q = c.req.valid<Map<String, dynamic>>('query');
  return c.ok({'query': q['q']});
});

// Parâmetros de rota
app.get('/posts/:id', [zValidator('param', z.map({'id': z.string()}))], (c) {
  final params = c.req.valid<Map<String, dynamic>>('param');
  return c.ok({'id': params['id']});
});
```

### Erro customizado via hook

```dart
app.post('/items', [
  zValidator('json', schema, (ZardResult result, c) {
    if (!result.success) {
      return c.status(422).json({'issues': result.error?.format()});
    }
    return null;
  }),
], handler);
```

### Targets disponíveis

| `target` | Fonte |
|---|---|
| `'json'` | JSON body |
| `'query'` | Query string |
| `'param'` | Parâmetros de rota |
| `'form'` | Form body (urlencoded ou multipart) |
| `'header'` | Headers da requisição |

---

## `validator()` — controle total (núcleo do Darto)

Não requer `darto_validator`. Use `package:darto/validator.dart` + `zard` diretamente.

```dart
import 'package:darto/darto.dart';
import 'package:darto/validator.dart';
import 'package:zard/zard.dart';

final userSchema = z.map({
  'name':  z.string().min(1),
  'email': z.string().email(),
  'age':   z.int().min(0).max(150),
});

// 400 em caso de falha — você decide o formato
app.post('/users', [
  validator('json', (value, c) {
    final result = userSchema.safeParse(value);
    if (!result.success) return c.badRequest({'errors': result.error?.format()});
    return result.data;
  }),
], (Context c) {
  final data = c.req.valid<Map<String, dynamic>>('json');
  return c.created({'user': data});
});

// 401 em caso de falha — qualquer status code funciona
app.post('/login', [
  validator('json', (value, c) {
    final result = loginSchema.safeParse(value);
    if (!result.success) return c.status(401).json({'errors': result.error?.format()});
    return result.data;
  }),
], (Context c) {
  final credentials = c.req.valid<Map<String, dynamic>>('json');
  return c.ok({'message': 'Bem-vindo, ${credentials['email']}!'});
});
```

Suporta os mesmos targets que `zValidator`.

---

## Comparação

| | `validator()` | `zValidator()` |
|---|---|---|
| Pacote | `darto` (core) | `darto_validator` |
| Biblioteca de schema | você escolhe | zard (embutido) |
| Resposta de erro | você controla | 400 automático + hook opcional |

---

## Schemas com zard (exemplos)

```dart
// String
z.string().min(1).max(255)
z.string().email()
z.string().url()
z.string().regex(r'^[a-z]+$')

// Número
z.int().min(0).max(150)
z.double().positive()

// Booleano
z.bool()

// Mapa (objeto)
z.map({
  'name':  z.string().min(1),
  'email': z.string().email(),
})

// Lista
z.list(z.string())

// Opcional
z.string().optional()

// Nullable
z.string().nullable()
```

---

## Exemplo completo com zValidator

```dart
import 'package:darto/darto.dart';
import 'package:darto_validator/darto_validator.dart';

final userSchema = z.map({
  'name': z.string().min(1),
  'email': z.string().email(),
  'age': z.int().min(0).max(150),
});

final searchSchema = z.map({
  'q': z.string().min(1),
});

final postParamSchema = z.map({
  'id': z.string().min(1),
});

void main() {
  final app = Darto();

  app.onError((err, c) => c.internalError({'error': err.toString()}));

  // Body JSON
  app.post('/users', [zValidator('json', userSchema)], (Context c) {
    final data = c.req.valid<Map<String, dynamic>>('json');
    return c.created({'user': data});
  });

  // Query params
  app.get('/search', [zValidator('query', searchSchema)], (Context c) {
    final query = c.req.valid<Map<String, dynamic>>('query');
    return c.ok({'results': [], 'query': query['q']});
  });

  // Params de rota
  app.get('/posts/:id', [zValidator('param', postParamSchema)], (Context c) {
    final params = c.req.valid<Map<String, dynamic>>('param');
    return c.ok({'post': params['id']});
  });

  // Erro customizado (422 ao invés de 400)
  app.post('/items', [
    zValidator('json', userSchema, (ZardResult result, c) {
      if (!result.success) {
        return c.status(422).json({
          'message': 'Entidade não processável',
          'issues': result.error?.format(),
        });
      }
      return null;
    }),
  ], (Context c) {
    final data = c.req.valid<Map<String, dynamic>>('json');
    return c.created({'item': data});
  });

  app.listen(3000);
}
```
