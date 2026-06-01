# MTK read-only dump runbook

Goal: create a verified, **read-only** copy of the device's partitions before any
destructive action. This runbook never writes to the device.

> Prerequisites: drivers + mtkclient installed (DRIVER-INSTALL-GUIDE-WINDOWS.md), and
> `list-usb-devices.ps1` shows the R1.

## 0. Safety preconditions

- You own this device.
- You have downloaded the official stock firmware for your installed version.
- You will only run **read** (`r`) operations in this runbook.
- Output goes to `firmware/dumps/` (gitignored) and is never shared publicly.

## 1. Enter BROM / preloader read mode

The R1 has no volume buttons. Typical flow:

1. Power the device off.
2. Start mtkclient in read mode (commands below), then plug in USB so the tool catches
   the preloader/BROM window.

> If mtkclient cannot catch the BROM window on Windows, retry, or use a Linux host
> (more reliable USB timing). Do not force anything.

## 2. Read the partition table first

```powershell
.\.venv\Scripts\Activate.ps1
$OUT = "firmware\dumps"
mkdir $OUT -Force | Out-Null

# Print the GPT / partition layout (read-only)
python -m mtkclient.mtk printgpt
```

Record the partition list — you will dump each relevant partition by name.

## 3. Dump partitions (read-only) in priority order

Dump the small, critical partitions first, then the large system partitions.

```powershell
# Critical boot chain
python -m mtkclient.mtk r preloader      "$OUT\preloader.bin"
python -m mtkclient.mtk r boot           "$OUT\boot.img"
python -m mtkclient.mtk r vendor_boot    "$OUT\vendor_boot.img"
python -m mtkclient.mtk r vbmeta         "$OUT\vbmeta.img"
python -m mtkclient.mtk r dtbo           "$OUT\dtbo.img"

# System set (names vary; use printgpt output)
python -m mtkclient.mtk r super          "$OUT\super.img"
# or, if not A/B super:
# python -m mtkclient.mtk r system        "$OUT\system.img"
# python -m mtkclient.mtk r vendor        "$OUT\vendor.img"
# python -m mtkclient.mtk r product       "$OUT\product.img"
# python -m mtkclient.mtk r odm           "$OUT\odm.img"
```

### Device-private partitions (keep private!)

If readable, these are useful for your own restore but must **never** be shared:

```powershell
python -m mtkclient.mtk r persist        "$OUT\persist.img"
python -m mtkclient.mtk r nvdata         "$OUT\nvdata.img"
python -m mtkclient.mtk r nvram          "$OUT\nvram.img"
python -m mtkclient.mtk r protect1       "$OUT\protect1.img"
python -m mtkclient.mtk r protect2       "$OUT\protect2.img"
```

### userdata (optional, encryption caveats)

`userdata` is typically file-based-encrypted; a raw dump may not restore cleanly to a
usable state. Only dump it if you understand those limits:

```powershell
# python -m mtkclient.mtk r userdata     "$OUT\userdata.img"
```

## 4. Hash everything

```powershell
.\scripts\verify-hashes.ps1 -Path firmware\dumps -OutFile firmware\hashes\dump-manifest.sha256
```

## 5. Archive offline

- Copy `firmware\dumps\` + `firmware\hashes\dump-manifest.sha256` to offline storage.
- Re-run `verify-hashes.ps1 -Verify` against the manifest after copying to confirm integrity.

## What NOT to do here

- No `w` (write), `wl`, `e` (erase), or bootloader unlock commands in this runbook.
- Do not upload nvram/nvdata/persist/protect/userdata anywhere.
- Do not extract or test any API keys/tokens found inside these images.
