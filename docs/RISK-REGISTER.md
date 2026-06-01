# Risk register

Recovery-first means: assume any write to the device can brick it or wipe data, and
make sure you can always get back to stock first.

## Risk levels for source material

When you collect external repos/docs, classify each one:

- **GREEN** — official Rabbit sources and standard Android tooling. Safe to use as
  documented (official firmware, Flash Tool, kernel source, Creations SDK, ADB/fastboot,
  mtkclient for read-only operations).
- **YELLOW** — community tooling useful for study; verify before running, and never run
  write/unlock steps until you have a verified stock restore.
- **RED** — research-only. Anything describing Rabbit cloud impersonation, account/activation
  keys, websocket auth, TLS fingerprinting, Intern/subscription bypass, or testing of
  found/leaked keys. **Read for understanding the architecture only. Do not execute.**

## Top risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Bootloader unlock wipes userdata | Permanent data loss | Do a read-only dump + hashes and have official stock restore ready **before** unlocking |
| Bad flash bricks device | Device unusable | Keep official firmware + Flash Tool; verify image hashes before flashing |
| Leaking device-private partitions | Privacy / identity exposure | `firmware/dumps/` is gitignored; never publish nvram/nvdata/persist/userdata |
| Committing your provider keys | Credential leak / cost | `.gitignore` + `scan-for-secrets.ps1` |
| Embedding keys in the Creation app | Keys exposed on device/frontend | Keys live only in the backend proxy `.env` |
| Temptation to test found keys | Account abuse / illegal | Hard rule: only your own keys, only from `private/.env.local` |

## Hard order of operations

1. Record device info (version, IMEI, serial — kept private).
2. Download official stock firmware + Flash Tool + drivers.
3. Read-only partition dump with mtkclient.
4. Hash every image (`scripts/verify-hashes.ps1`).
5. Archive the dump offline.
6. Only then consider unlock/flash/custom ROMs.
