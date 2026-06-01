# R1 Creation app spec

A third-party Rabbit Creation: a static HTML/CSS/JS app sized for the R1 screen,
installed via QR code. It contains **no API keys** — it talks to your backend proxy.

## Constraints

- Screen: 240 x 282 px. Design for a tiny, dark UI with large touch targets.
- Static front-end only (HTML/CSS/JS). Hostable on Netlify / GitHub Pages.
- Hardware affordances available via the Creations SDK: scroll wheel events, side
  (PTT) button events, accelerometer, speaker output. The app degrades gracefully in a
  desktop browser (keyboard fallbacks) for development.

## Behavior

- **Provider switch:** MiniMax / DeepSeek / SiliconFlow (selected provider is sent to
  the proxy; the proxy decides the real routing).
- **Modes:** Chat, Vision note (image + prompt), Tool runner (prompt presets),
  Voice response (TTS hook, optional).
- **PTT / side button:** triggers "ask AI" (send current input).
- **Scroll wheel:** scroll the transcript / cycle provider.

## Networking

The app calls only your proxy:

```
POST {PROXY_BASE_URL}/r1/chat
{ "provider": "minimax" | "deepseek" | "siliconflow",
  "messages": [ { "role": "user", "content": "..." } ] }
```

It never calls MiniMax/DeepSeek/SiliconFlow directly and never holds provider keys.
Configure `PROXY_BASE_URL` in `js/config.js`.

## Files

```
minimax-deepseek-siliconflow-assistant/
  index.html
  css/style.css
  js/config.js        # PROXY_BASE_URL only — no keys
  js/app.js           # UI + fetch to proxy + hardware hooks
  install-qr/README.md
  README.md
```

## Install via QR

1. Host the folder (Netlify/GitHub Pages) over HTTPS.
2. Generate a QR pointing at the hosted `index.html` (see `install-qr/README.md`).
3. Scan with the R1 to install the Creation.

Installing an existing/public Creation does not consume Rabbit Intern tasks.
