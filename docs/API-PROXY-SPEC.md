# API proxy spec

A small Node/Express backend that holds your provider keys server-side and exposes a
single OpenAI-style chat endpoint to the R1 Creation. The device never sees raw keys.

## Endpoints

### `GET /health`
Returns `{ ok: true }` plus which providers are configured (booleans only, never values).

### `POST /r1/chat`
Request:
```json
{
  "provider": "minimax",
  "messages": [ { "role": "user", "content": "hello" } ],
  "model": "optional-model-override",
  "temperature": 0.7
}
```
Response (normalized):
```json
{ "provider": "minimax", "model": "...", "content": "...assistant reply..." }
```

## Providers

Each provider module exposes `chat({ messages, model, temperature })` and reads its key
+ base URL from environment variables. All three providers are OpenAI-compatible.

| Provider | Env key | Base URL env (default) |
|----------|---------|------------------------|
| MiniMax | `MINIMAX_API_KEY` | `MINIMAX_BASE_URL` (`https://api.minimax.io/v1`) |
| DeepSeek | `DEEPSEEK_API_KEY` | `DEEPSEEK_BASE_URL` (`https://api.deepseek.com`) |
| SiliconFlow | `SILICONFLOW_API_KEY` | `SILICONFLOW_BASE_URL` (`https://api.siliconflow.cn/v1`) |

Routing/fallback:
```
DEFAULT_PROVIDER=minimax
FALLBACK_PROVIDER=deepseek
SECOND_FALLBACK_PROVIDER=siliconflow
```

If a request doesn't specify `provider`, the proxy uses `DEFAULT_PROVIDER`. The proxy
**may** fall back to the configured fallbacks on a 5xx/network error (off by default;
enable with `ENABLE_FALLBACK=true`).

## Security

- Keys come only from `proxy/.env` (gitignored). Never logged.
- CORS limited to your Creation's origin via `ALLOWED_ORIGIN`.
- Optional shrt-lived app token: set `APP_TOKEN`; the Creation sends
  `Authorization: Bearer <APP_TOKEN>`. This is **your** app token, not a Rabbit token.
- The proxy never talks to Rabbit's cloud and never uses Rabbit credentials.

## Run

```bash
cp ../templates/.env.example .env   # then edit with your keys
npm install
npm start                            # listens on PORT (default 8787)
```
