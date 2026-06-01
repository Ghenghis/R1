# R1 Assistant (third-party Creation)

A static Creation for the Rabbit R1 (240×282). It calls **your** backend proxy — it
contains **no API keys**.

## Configure

Edit `js/config.js`:

- `PROXY_BASE_URL` — your proxy URL (local dev: `http://localhost:8787`; device: your
  deployed HTTPS proxy).
- `APP_TOKEN` — only if your proxy sets one (your own token, not a Rabbit token).

## Develop in a browser

Serve the folder over a local web server (so `fetch` works) while the proxy runs:

```bash
# from this folder
python -m http.server 5173
# open http://localhost:5173
```

Type a prompt and press Enter (simulates the PTT "ask AI"). Use the top buttons to
switch provider/mode.

## Install on the R1 (QR)

1. Host this folder over HTTPS (Netlify / GitHub Pages).
2. Generate a QR pointing at the hosted `index.html` (see `install-qr/README.md`).
3. Scan it with the R1 to install. Installing an existing Creation does not consume
   Rabbit Intern tasks.

## Hardware mapping

- Side / PTT button → ask AI (send current input).
- Scroll wheel → cycle provider.
- Voice mode → speaks replies (browser TTS / on-device speaker).

All hardware hooks are optional and no-op safely in a desktop browser.
