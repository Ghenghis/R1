# Install via QR

The R1 installs a Creation by scanning a QR code that points at the hosted app URL.

## 1. Host the app

Deploy the parent folder (`minimax-deepseek-siliconflow-assistant/`) to any static host
over HTTPS, e.g.:

- **Netlify:** drag-and-drop the folder, or `netlify deploy`.
- **GitHub Pages:** push the folder and enable Pages for the branch/dir.

You'll get a URL like `https://your-site.netlify.app/index.html`.

## 2. Generate the QR

Use any QR generator pointing at that URL. From the command line, for example:

```bash
# Node (one option)
npx qrcode "https://your-site.netlify.app/index.html" -o creation-qr.png

# Python (one option)
pip install qrcode[pil]
python -c "import qrcode; qrcode.make('https://your-site.netlify.app/index.html').save('creation-qr.png')"
```

Save the image here as `creation-qr.png`.

## 3. Scan with the R1

Use the R1's Creation install flow to scan `creation-qr.png`. Installing a public/existing
Creation does not require Rabbit Intern tasks.

> Reminder: the hosted app must point `PROXY_BASE_URL` (in `js/config.js`) at your
> deployed HTTPS proxy before you build the QR, so the installed Creation can reach it.
