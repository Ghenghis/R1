# Secrets policy

This kit handles exactly one class of secret: **your own** model-provider API keys
(MiniMax, DeepSeek, SiliconFlow). Nothing else.

## Rules

1. **Your keys only.** The only keys this kit ever reads or transmits are the ones
   you place in `private/.env.local` (for testing) or `proxy/.env` (for running the
   proxy). These are keys you personally own and are authorized to use.

2. **No found keys.** Keys discovered in GitHub repos, gists, firmware images, APKs,
   partition dumps, logs, screenshots, or network captures are **never** used or
   "validated." If you find a key in a dump, treat it as private device data and do
   not test it.

3. **No Rabbit cloud credentials.** Rabbit Intern tokens, Rabbit account/activation
   keys, websocket auth material, and device-identity/TLS material are never extracted,
   tested, used, or stored by this kit.

4. **Keys never reach the device.** The Rabbit Creation app contains no keys. It calls
   your backend proxy over HTTPS; the proxy holds the real provider keys server-side.

5. **Keys stay out of git.** `private/` and all `*.env`/`*.env.local` files are
   gitignored. Run `scripts/scan-for-secrets.ps1` before committing.

6. **Device-private dumps stay private.** Never publish `nvram`, `nvdata`, `persist`,
   `protect`, IMEI/modem calibration, or `userdata` images. These live under
   `firmware/dumps/` which is gitignored.

## Where secrets live

| File | Purpose | Committed? |
|------|---------|-----------|
| `templates/.env.example` | placeholder names only, no values | yes |
| `templates/.env.local.example` | placeholder names only, no values | yes |
| `proxy/.env` | real keys for running the proxy | **no** |
| `private/.env.local` | real keys for the key health check | **no** |

## If a key leaks

Rotate it immediately at the provider dashboard, then run
`scripts/scan-for-secrets.ps1` to confirm no key remains in the working tree before
committing or zipping the kit.
