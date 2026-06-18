# 07 — WebSocket (`darto_ws`)

WebSocket no **mesmo port** do servidor HTTP — sem servidor ou port separado.

```yaml
dependencies:
  darto_ws: ^1.0.0
```

---

## Echo simples

```dart
import 'package:darto/darto.dart';
import 'package:darto_ws/darto_ws.dart';

void main() async {
  final app = Darto();

  app.get('/ws', [], upgradeWebSocket((c) => WSHandler(
    onOpen:    (ws) => ws.send('conectado'),
    onMessage: (event, ws) => ws.send('echo: ${event.text}'),
    onClose:   (ws) => print('${ws.id} desconectado'),
    onError:   (err, ws) => print('erro: $err'),
  )));

  await app.listen(3000, () => print('Server em http://localhost:3000'));
}
```

---

## Chat com rooms (WsHub)

`WsHub` rastreia conexões e rooms. Instale seu middleware uma vez.

```dart
final hub = WsHub();
app.use(hub.middleware());

// Room chat — broadcast para todos no room (exceto o sender)
app.get('/chat/:room', [], upgradeWebSocket((c) {
  final room = c.req.param('room')!;
  return WSHandler(
    onOpen: (ws) {
      ws.join(room);
      ws.to(room).except(ws).send('${ws.id} entrou');
    },
    onMessage: (event, ws) =>
        ws.to(room).sendJson({'from': ws.id, 'text': event.text}),
    onClose: (ws) {
      // ws.leave(room) acontece automaticamente ao fechar
      ws.to(room).send('${ws.id} saiu');
    },
  );
}));

// Broadcast de HTTP → WebSocket room
app.post('/announce/:room', [], (Context c) async {
  final body = await c.req.json();
  hub.to(c.req.param('room')!).sendJson({'announce': body['text']});
  return c.noContent();
});

// Inspecionar estado
app.get('/', [], (Context c) => c.ok({
  'connections': hub.connections,
  'rooms': hub.rooms.toList(),
}));
```

---

## Mensagens JSON

```dart
app.get('/ws/json', [], upgradeWebSocket((c) => WSHandler(
  onMessage: (event, ws) {
    final payload = event.json; // Map<String, dynamic>
    ws.sendJson({'echo': payload});
  },
)));
```

---

## Parâmetros e estado de middleware

O `Context` é totalmente resolvido antes do upgrade — params de rota, headers e valores definidos por middleware estão disponíveis:

```dart
app.get('/chat/:room', [jwtMiddleware], upgradeWebSocket((c) {
  final room   = c.req.param('room')!;
  final userId = c.get<String>('userId'); // definido pelo middleware de auth

  return WSHandler(
    onOpen:    (ws) => ws.send('$userId entrou em "$room"'),
    onMessage: (event, ws) => ws.send('[$room] ${event.text}'),
  );
}));
```

---

## Callbacks de `WSHandler`

| Callback | Assinatura | Quando |
|---|---|---|
| `onOpen` | `(DartoWebSocket ws)` | Handshake completo |
| `onMessage` | `(WSEvent event, DartoWebSocket ws)` | Frame recebido |
| `onClose` | `(DartoWebSocket ws)` | Conexão fechada |
| `onError` | `(Object error, DartoWebSocket ws)` | Erro de protocolo |

---

## Métodos de `DartoWebSocket`

| Método | Descrição |
|---|---|
| `send(String)` | Enviar frame de texto |
| `sendJson(Map)` | Codificar e enviar como JSON |
| `sendBytes(List<int>)` | Enviar frame binário |
| `close([code, reason])` | Fechar conexão |
| `join(room)` | Entrar em um room |
| `leave(room)` | Sair de um room |
| `to(room)` | Retorna broadcaster para o room |
| `id` | ID único da conexão |

---

## Broadcaster (WsHub / ws.to)

```dart
// A partir de um handler WebSocket
ws.to(room).send('mensagem');
ws.to(room).sendJson({'key': 'value'});
ws.to(room).except(ws).send('para todos menos o remetente');

// A partir de um route HTTP
hub.to(room).sendJson({'announce': 'alguém enviou isso via HTTP'});
```
