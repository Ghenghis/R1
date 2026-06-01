# Run me first

Quick path for the two things you asked for: **back up the Rabbit R1** and **build
the app/proxy**. Run these on the PC the R1 is plugged into.

## A. Full Rabbit R1 backup (read-only, nothing excluded)

Prereqs (one time):
- Python 3.11/3.12 installed.
- MediaTek Preloader USB VCOM driver installed (you already did this).
- UsbDk installed (mtkclient needs it on Windows) — see `docs/DRIVER-INSTALL-GUIDE-WINDOWS.md`.

Then, from the kit root in PowerShell:

```powershell
# Power the R1 OFF first. The script will tell you when to plug it in.
.\scripts\full-backup.ps1
```

This sets up mtkclient, prints the partition table, dumps **every** partition into
`firmware\dumps\`, and writes SHA-256 hashes into `firmware\hashes\`.

After it finishes:

```powershell
# Copy firmware\dumps + firmware\hashes to offline storage, then re-verify:
.\scripts\verify-hashes.ps1 -Verify
```

Keep `nvram/nvdata/persist/protect/userdata` images private — never upload them.
Full details: `docs/MTK-DUMP-RUNBOOK.md`. Restore path: `docs/STOCK-RESTORE-RUNBOOK.md`.

## B. Backend proxy (your own keys)

```powershell
copy templates\.env.example proxy\.env
notepad proxy\.env          # add YOUR MiniMax/DeepSeek/SiliconFlow keys
cd proxy
npm install
npm start                    # http://localhost:8787
```

Test it:
```powershell
curl http://localhost:8787/health
```

## C. R1 Creation app

```powershell
# point the app at your proxy:
notepad creations\minimax-deepseek-siliconflow-assistant\js\config.js
# serve for local testing:
cd creations\minimax-deepseek-siliconflow-assistant
python -m http.server 5173   # open http://localhost:5173
```

Deploy + QR install: `creations/.../install-qr/README.md`.

## D. (Optional) validate your own provider keys

```powershell
New-Item -ItemType Directory -Force private | Out-Null
copy templates\.env.local.example private\.env.local
notepad private\.env.local   # your own keys only
. .\scripts\load-env-local.ps1
.\scripts\test-provider-keys-safe.ps1 -Mode MaskOnly
.\scripts\test-provider-keys-safe.ps1 -Mode Models
# spends a tiny bit of credit:
.\scripts\test-provider-keys-safe.ps1 -Mode ChatSmoke -Confirm
```

## Safety

Read `docs/SECRETS-POLICY.md` and `docs/RISK-REGISTER.md`. This kit only uses your own
keys, only does read-only device operations until you choose to flash, and never touches
Rabbit's cloud or credentials.
