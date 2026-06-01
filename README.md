# Rabbit R1 Safe Lab

A recovery-first toolkit for working with **your own** Rabbit R1, plus a third-party
Creation app and a backend API proxy that uses **your own** model-provider keys.

## Scope (what this kit does and does not do)

This kit is intentionally scoped to things you can do safely and legitimately with
hardware you own:

- Preserve and recover stock rabbitOS (official firmware + read-only partition dump + hashes).
- Build a third-party Rabbit **Creation** (a static HTML/CSS/JS app installed via QR).
- Run a backend **proxy** so the device app never holds raw provider keys.
- Route the proxy to MiniMax / DeepSeek / SiliconFlow using **your own** keys from a local `.env`.

### Explicitly out of scope

This kit will **not** help with, and the scripts here will refuse to do:

- Bypassing Rabbit Intern credits or subscriptions, or any Rabbit service.
- Extracting, testing, or using Rabbit cloud tokens, account/activation keys, or websocket auth material.
- Using or "validating" API keys found in GitHub repos, gists, firmware, APKs, dumps, logs, or screenshots — only your own keys, supplied by you, are ever used.
- TLS/client fingerprint spoofing or fake device identity.
- Automating or impersonating Rabbit's private cloud endpoints.

See [docs/SECRETS-POLICY.md](docs/SECRETS-POLICY.md) and
[docs/RISK-REGISTER.md](docs/RISK-REGISTER.md).

## Layout

```
rabbit-r1-safe-lab/
  README.md
  docs/                  recovery + restore + policy runbooks
  scripts/               PowerShell helpers (clone, hash, usb, secret scan, key health)
  firmware/
    official/            official RabbitOS firmware you download
    dumps/               read-only partition dumps you create (gitignored)
    hashes/              SHA-256 manifests
  creations/             third-party R1 Creation app (no embedded keys)
  proxy/                 backend API proxy (your own keys via .env)
  templates/             .env templates
  private/               your local secrets (gitignored, never committed)
```

## Quick start

1. Recovery first — read [docs/RECOVERY-FIRST-CHECKLIST.md](docs/RECOVERY-FIRST-CHECKLIST.md)
   and complete a read-only dump + hashes before touching the bootloader.
2. Proxy — see [proxy/README.md](proxy/README.md). Copy `templates/.env.example` to
   `proxy/.env`, add your own keys, `npm install`, `npm start`.
3. Creation app — see
   [creations/minimax-deepseek-siliconflow-assistant/README.md](creations/minimax-deepseek-siliconflow-assistant/README.md).
   Point it at your proxy URL and install via QR.

## Safety defaults

- `private/` and all `*.env*` (except `*.example`) are gitignored.
- `scripts/scan-for-secrets.ps1` blocks accidental key commits.
- `scripts/test-provider-keys-safe.ps1` only reads keys from `private/.env.local`.
- Partition dumps under `firmware/dumps/` are gitignored and must never be shared publicly.
