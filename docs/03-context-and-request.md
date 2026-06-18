# 03 — Context API e Request

O objeto `Context` (`c`) é o único ponto de entrada para tudo relacionado a request/response.

---

## Helpers de resposta

```dart
// Sucesso
c.ok([body])            // 200
c.created([body])       // 201
c.noContent()           // 204

// Erros de cliente
c.badRequest([body])    // 400
c.unauthorized([body])  // 401
c.forbidden([body])     // 403
c.notFound([body])      // 404
c.conflict([body])      // 409

// Erro de servidor
c.internalError([body]) // 500

// Respostas tipadas
c.json(data, [status])  // application/json
c.text(str, [status])   // text/plain
c.html(str, [status])   // text/html

// Body raw (HonoJS-style)
c.body('obrigado!')
c.body(bytes, 200, {'Content-Type': 'image/png'})
c.body(null, 204)

// Status customizado + body
c.status(206).json(data)
c.status(418).text("I'm a teapot")

// Binário
c.binary(bytes, status: 200, contentType: 'image/png')

// Arquivo inline (stream — sem bufferizar o arquivo inteiro)
await c.file('/path/to/file.pdf')
await c.file('/path/to/image.png', contentType: 'image/png')

// Forçar download (Content-Disposition: attachment)
await c.download('/path/to/report.csv')
await c.download('/path/to/report.csv', filename: 'export.csv')

// Redirect
c.redirect('/new-path')
c.redirect('/login', 301)
```

> `c.file()` e `c.download()` usam streaming — arquivos de 2 GB consomem a mesma RAM que 10 KB.
> Retornam 404 automaticamente se o arquivo não existe.

---

## Headers de resposta

```dart
c.header('X-Request-Id', uuid);
```

---

## Leitura do body (`c.req`)

```dart
// JSON → Map<String, dynamic>
final body = await c.req.json();

// JSON → DTO tipado
final user = await c.req.json<User>(User.fromJson);

// Texto (UTF-8)
final raw = await c.req.text();

// Bytes
final bytes  = await c.req.blob();        // Uint8List
final buffer = await c.req.arrayBuffer(); // ByteBuffer
final stream = c.req.body;                // Stream<List<int>> (consumido uma vez)

// Form (urlencoded ou multipart)
final form = await c.req.formData();
```

---

## Informações da URL

```dart
String method = c.req.method; // 'GET', 'POST', …
String path   = c.req.path;   // '/users/42'
Uri    url    = c.req.url;    // Uri completo
String ip     = c.req.ip;     // IP remoto
```

---

## Headers da requisição

```dart
String?             c.req.header('authorization')  // header único
Map<String, String> c.req.headers                  // todos (imutável)
```

---

## Estado por request (`c.set` / `c.get`)

```dart
// Armazenar valor (usado tipicamente em middlewares)
c.set('userId', '42');

// Recuperar valor
final id = c.get<String>('userId');
```

---

## Atalho para usuário autenticado

```dart
// Definido pelo middleware de auth
c.user = {'id': '42', 'role': 'admin'};

// Lido no handler
final user = c.user; // Map<String, dynamic>?
```

---

## Dados validados

```dart
// Recuperar dados armazenados por validator() ou zValidator()
final data  = c.req.valid<Map<String, dynamic>>('json');
final query = c.req.valid<Map<String, dynamic>>('query');
```

---

## Upload de arquivos (`c.req.parseBody`)

### Em memória (arquivos pequenos)

```dart
app.post('/avatar', [], (Context c) async {
  final body = await c.req.parseBody();
  final file = body['avatar'] as UploadedFile;

  print(file.name);     // 'photo.jpg'
  print(file.mimeType); // 'image/jpeg'
  print(file.size);     // tamanho em bytes

  await File('uploads/${file.name}').writeAsBytes(file.bytes);
  return c.ok({'name': file.name, 'size': file.size});
});
```

### Stream para disco (arquivos grandes)

```dart
app.post('/video', [], (Context c) async {
  final body = await c.req.parseBody(saveDir: 'uploads');
  final file = body['video'] as UploadedFile;

  // file.bytes está vazio — dados já estão no disco
  print(file.path);     // 'uploads/1716123456789_video_482910374.mp4'
  print(file.isOnDisk); // true
  return c.ok({'path': file.path, 'size': file.size});
});
```

### Múltiplos arquivos

```dart
app.post('/gallery', [], (Context c) async {
  final body  = await c.req.parseBody(saveDir: 'uploads');
  final raw   = body['photos'];
  final files = raw is List ? raw.cast<UploadedFile>() : [raw as UploadedFile];

  return c.ok({'count': files.length});
});
```

### Campos mistos (texto + arquivo)

```dart
app.post('/product', [], (Context c) async {
  final body  = await c.req.parseBody(saveDir: 'uploads');
  final name  = body['name']  as String;
  final price = body['price'] as String;
  final image = body['image'] as UploadedFile;

  return c.created({'name': name, 'price': double.parse(price), 'image': image.path});
});
```

### Propriedades de `UploadedFile`

| Propriedade | Tipo | Descrição |
|---|---|---|
| `fieldname` | `String` | Nome do campo no formulário |
| `name` | `String` | Nome original do arquivo |
| `bytes` | `Uint8List` | Conteúdo (vazio quando `isOnDisk`) |
| `mimeType` | `String` | MIME type dos headers do part |
| `size` | `int` | Tamanho em bytes |
| `path` | `String?` | Caminho no disco (quando `saveDir`) |
| `isOnDisk` | `bool` | `true` quando salvo em disco |

### Content-Types suportados por `parseBody`

| Content-Type | Tipo retornado |
|---|---|
| `application/json` | `Map<String, dynamic>` |
| `application/x-www-form-urlencoded` | `String` por campo |
| `multipart/form-data` | `String` (texto) ou `UploadedFile` |

---

## Introspecção da resposta

```dart
int       c.statusCode;     // status atual (200 se não definido)
Response? c.response;       // objeto Response atual ou null
c.respond(existingResponse); // definir um Response diretamente
c.clearResponse();           // resetar (usado por combiners de middleware)
```

---

## Metadados da rota

```dart
List<RouteSpec>? routes = c.matchedRoutes;
String? pattern = c.routePath;      // '/posts/:id'
String? prefix  = c.baseRoutePath;  // '/api'  (padrão do grupo)
String? base    = c.basePath;       // '/api'  (resolvido com valores reais)
```

---

## Status codes HTTP (constantes)

```dart
import 'package:darto/darto.dart';

// 2xx
OK                    // 200
CREATED               // 201
ACCEPTED              // 202
NO_CONTENT            // 204

// 3xx
MOVED_PERMANENTLY     // 301
FOUND                 // 302
NOT_MODIFIED          // 304

// 4xx
BAD_REQUEST           // 400
UNAUTHORIZED          // 401
FORBIDDEN             // 403
NOT_FOUND             // 404
METHOD_NOT_ALLOWED    // 405
CONFLICT              // 409
PAYLOAD_TOO_LARGE     // 413
UNPROCESSABLE_ENTITY  // 422
TOO_MANY_REQUESTS     // 429

// 5xx
INTERNAL_SERVER_ERROR // 500
BAD_GATEWAY           // 502
SERVICE_UNAVAILABLE   // 503
GATEWAY_TIMEOUT       // 504
```

---

## Response Factories (controle total)

```dart
Response.json(data,  {int status = 200, Map<String, String> headers = const {}})
Response.text(str,   {int status = 200, Map<String, String> headers = const {}})
Response.html(str,   {int status = 200, Map<String, String> headers = const {}})
Response.bytes(bytes, {int status = 200, String contentType = '…', Map<String, String> headers = const {}})
const Response.empty({int status = 204})
```

---

## Cookies

```dart
import 'package:darto/cookie.dart';

// Ler
Map<String, String> all   = getCookies(c);
String?             value = getCookie(c, 'session');

// Escrever
setCookie(c, 'session', 'abc123');
setCookie(c, 'session', 'abc123', CookieOptions(
  path: '/',
  httpOnly: true,
  secure: true,
  sameSite: 'Strict',
  maxAge: 3600,
  expires: DateTime.now().add(Duration(hours: 1)),
  domain: '.example.com',
));

// Deletar
deleteCookie(c, 'session');

// Cookies assinados (HMAC-SHA256)
await setSignedCookie(c, 'uid', '42', secret);
final uid = await getSignedCookie(c, secret, 'uid'); // null se adulterado

// Gerar sem definir
String raw    = generateCookie('name', 'value', options);
String signed = await generateSignedCookie('name', 'value', secret);
```

---

## Sessions (cookie assinado)

```dart
import 'package:darto/session.dart';

// Registrar uma vez globalmente
app.use(sessionMiddleware(
  secret: 'pelo-menos-32-chars-de-segredo!!',
  duration: 60 * 30,           // maxAge em segundos (padrão: 1800)
  cookieName: 'darto.session', // opcional, este é o padrão
));

// Escrever / atualizar
app.post('/login', [], (c) async {
  final body = await c.req.json();
  await sessionContext(c).update({'userId': body['id'], 'role': 'user'});
  return c.ok({'message': 'logado'});
});

// Ler
app.get('/me', [], (c) {
  final data = sessionContext(c).get(); // Map<String, dynamic>? — null se sem sessão
  if (data == null) return c.unauthorized({'error': 'sem sessão'});
  return c.ok(data);
});

// Deletar
app.post('/logout', [], (c) {
  sessionContext(c).delete();
  return c.ok({'message': 'deslogado'});
});
```

| Método | Retorna | Descrição |
|---|---|---|
| `sessionContext(c).get()` | `Map<String, dynamic>?` | Dados da sessão; `null` se inválida |
| `sessionContext(c).update(data)` | `Future<void>` | Substituir dados e escrever cookie assinado |
| `sessionContext(c).delete()` | `void` | Limpar dados e deletar cookie |
