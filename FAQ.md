# FAQ — PAR2 HDD-Safe Automation Scripts

This FAQ exists to clarify **what this project does**, **what it does not do**, and
**why some design choices are intentional**.

If something feels “overly strict” or “not automatic enough”, read this first.

---

## Why does this project exist?

Because many PAR2 automation scripts are **actively dangerous**.

Common failure modes include:
- regenerating PAR files from corrupted data
- silently destroying the last good recovery state
- optimizing for CPU benchmarks instead of HDD behavior

This project enforces one hard rule:

Recovery data must never be regenerated unless existing data is proven clean.

---

## Is this suitable for frequently changing data?

No.

This project assumes data is **write-once or rarely modified**, such as archives,
backups, or cold storage.

It is intentionally not designed for:
- constantly changing working directories
- live datasets
- high-churn synchronization targets

---

## Why does the script sometimes refuse to regenerate PAR files?

Because regeneration would be unsafe.

Specifically:
- Existing PAR files failed verification
- Regenerating would lock in corrupted data as the new baseline

Stopping is the correct behavior.

---

## Why does this project use MultiPar (`par2j64.exe`)?

MultiPar provides:
- stricter verification semantics
- deterministic file enumeration
- better Windows and NTFS behavior
- improved stability compared to classic `par2.exe`

Some legacy PAR2 sets created with older tools may fail verification under
MultiPar even if files are intact. In such cases, a one-time regeneration
is required to migrate safely.

---

## What is recovery.padding.dat?

`recovery.padding.dat` is a structural padding file created when a dataset is too
small to form valid PAR2 blocks.

- It is part of the dataset
- It is persistent and never auto-deleted
- It ensures stable creation and verification
- It is included in hashes and verification

---

## Isn’t this too strict for home use?

No. Home users lose data more often due to **automation mistakes** than hardware.

This project is strict only where irreversible damage is possible.

---

## Final advice

If this tool ever refuses to act:
- stop
- investigate
- decide what you trust

Silence is worse than failure.
