# Rabbit R1 Safe Proxy

Backend that the R1 Creation app calls. Holds your own provider keys server-side; the
device never sees them. Talks only to MiniMax / DeepSeek / SiliconFlow — never to
Rabbit's cloud.

## Setup

```bash
cd proxy
cp ../templates/.env.example .env     # then edit .env with YOUR keys
npm install
npm run check                          # syntax check
npm start                              # listens on PORT (default 8787)
```

## Configure (`proxy/.env`)

Only your own keys. Leave a provider blank to disable it.

```
PORT=8787
ALLOWED_ORIGIN=*            # set to your Creation's origin in production
APP_TOKEN=                  # optional: your own bearer token for the device app
ENABLE_FALLBACK=false

MINIMAX_API_KEY=
DEEPSEEK_API_KEY=
SILICONFLOW_API_KEY=

MINIMAX_BASE_URL=https://api.minimax.io/v1
DEEPSEEK_BASE_URL=https://api.deepseek.com
SILICONFLOW_BASE_URL=https://api.siliconflow.cn/v1

DEFAULT_PROVIDER=minimax
FALLBACK_PROVIDER=deepseek
SECOND_FALLBACK_PROVIDER=siliconflow
```

## Endpoints

- `GET /health` — booleans for which providers are configured (never key values).
- `POST /r1/chat` — `{ provider, messages, model?, temperature? }` → `{ provider, model, content }`.

### Examples

```bash
curl http://localhost:8787/health

curl -X POST http://localhost:8787/r1/chat \
  -H "Content-Type: application/json" \
  -d '{"provider":"deepseek","messages":[{"role":"user","content":"hi"}]}'
```

If you set `APP_TOKEN`, add `-H "Authorization: Bearer <APP_TOKEN>"`.

## Notes

- Keys are read only from `proxy/.env` and never logged.
- This proxy uses no Rabbit credentials and never contacts Rabbit servers.
