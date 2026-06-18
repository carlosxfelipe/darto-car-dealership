# Darto Framework — Documentação de Referência

Darto é um framework web minimalista, rápido e type-safe para Dart, inspirado no Express e no Hono.

> **Tudo flui por um único conceito: `Context`.**

---

## Índice

| Arquivo | Conteúdo |
|---|---|
| [01-getting-started.md](./01-getting-started.md) | Instalação, Quick Start, CLI, estrutura gerada |
| [02-routing.md](./02-routing.md) | Rotas HTTP, parâmetros, grupos, Router standalone |
| [03-context-and-request.md](./03-context-and-request.md) | Context API completa — `c.req`, `c.set/get`, resposta |
| [04-middleware.md](./04-middleware.md) | Sistema de middleware, built-ins (CORS, JWT, Rate Limit…) |
| [05-validation.md](./05-validation.md) | Validação com `zValidator` e `validator()` |
| [06-auth.md](./06-auth.md) | JWT helpers, sessões, Basic/Bearer auth, OAuth, `darto_auth` |
| [07-websocket.md](./07-websocket.md) | WebSocket com `darto_ws` — echo, rooms, broadcast |
| [08-packages.md](./08-packages.md) | Ecossistema: env, static, inject, cache, jobs, mailer, openapi |
| [09-testing.md](./09-testing.md) | Testes com `darto_test` (supertest-style) |
| [10-project-structure.md](./10-project-structure.md) | Estrutura de projeto recomendada (NestJS-style) |

---

## Pacotes do ecossistema

| Pacote | Descrição |
|---|---|
| `darto` | Core — routing, middleware, context |
| `darto_cli` | CLI — scaffold, dev server, build, gerador de client |
| `darto_validator` | Validação via `zValidator` (Zod-style com zard) |
| `darto_ws` | WebSocket no mesmo port do HTTP |
| `darto_view` | Template engine (Mustache, Jinja…) |
| `darto_static` | Servir arquivos estáticos |
| `darto_env` | Carregador de `.env` |
| `darto_openapi` | Geração de spec OpenAPI 3.1 + UI Scalar |
| `darto_test` | Cliente de testes ergonômico |
| `darto_logger` | Logger estruturado + middleware de request |
| `darto_auth` | Hash de senha (PBKDF2) + session auth + OAuth |
| `darto_inject` | Injeção de dependência tipada (`Provider<T>`) |
| `darto_cache` | Cache com `MemoryCache` (LRU/TTL) e `RedisCache` |
| `darto_rate_limit` | `RateLimitStore` distribuído (Redis) |
| `darto_mailer` | Envio de e-mail — SMTP / console / memory |
| `darto_jobs` | Background jobs com retries — Memory / Redis |

---

## Conceitos-chave

```dart
typedef Handler    = FutureOr<Response>? Function(Context c);
typedef Middleware = FutureOr<void>      Function(Context c, Next next);
typedef Next       = Future<void>        Function();
```

- **Handler** — recebe `Context`, retorna `Response`.
- **Middleware** — recebe `Context` e `Next`. Chame `await next()` para passar o controle. Retornar sem chamar `next()` curto-circuita o pipeline.
- **Context** — ponto único de entrada para tudo relacionado a request/response.
