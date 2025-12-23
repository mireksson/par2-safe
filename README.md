# par2-safe
### Integrity-first PAR2 automation for home and consumer offline storage

A small set of PowerShell scripts for **safe, deterministic PAR2 generation and verification**
for **home users managing HDD/SSD offline backups and archives**.

This project is designed primarily for **personal use**, where:
- backups are stored offline
- data is organized in directory trees
- simplicity and correctness matter more than speed or automation magic

This project assumes backups are **write-once or rarely modified**.

This project prioritizes:
- correctness over cleverness
- explicit failure over silent corruption
- archive reality over theoretical optimization

---

## Typical use cases

- Home / consumer offline backups (HDD or SSD)
- External USB disks
- Cold storage archives
- Long-lived personal data (photos, media, documents)
- Tree-structured backup layouts

This is **not** a cloud backup system, snapshot system, or realtime monitor.

---

## Strengths

- **Correct semi-automation**  
  Automation that knows when to stop instead of guessing

- **Tree-based organization**  
  Works naturally with directory hierarchies and nested archives

- **Archive-first design**  
  Optimized for data that should not change often

- **Low complexity**  
  No databases, daemons, services, or special filesystems

---

## Features

- Per-directory PAR2 generation
- HDD-optimized block sizing
- Mixed-content directory handling
- Metadata-based change detection
- Mandatory verification before regeneration
- Protection against regenerating from corrupted data
- Int64-safe for very large files
- Sequential, archive-friendly I/O

---

## Directory Layout

Each protected directory contains a dedicated recovery subdirectory:

    <directory>
     ├─ files...
     └─ .recovery
         ├─ recovery.par2
         ├─ recovery.sha256
         └─ recovery.padding.dat   (only if required)

### recovery.padding.dat

For very small datasets, a **persistent padding file** is created to ensure
valid PAR2 block geometry.

- It is part of the dataset
- It is never deleted automatically
- It ensures stable creation and verification
- It is included in hashes and verification

---

## Scripts

### `par.update.ps1`
Main maintenance script.

Behavior:
- Walks directories recursively
- Generates PAR2 files when missing
- Regenerates PAR2 only if:
  - file metadata changed **and**
  - existing PAR2 verifies clean
- Refuses to regenerate if verification fails

This is the script you run periodically on your backups.

---

### `par.verify.ps1`
Read-only verification helper.

Use when you want to:
- Audit offline backups
- Detect bitrot
- Verify archives without modifying anything

---

### `fix.filenames.ps1`
Optional filename normalization helper.

Useful for:
- Cleaning up problematic filenames
- Preparing data before archiving
- Avoiding filesystem edge cases

---

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- **MultiPar command-line engine (`par2j64.exe`)**

Classic `par2.exe` is intentionally not used.
MultiPar provides stricter verification semantics and more reliable
Windows-native behavior.

---

## Design philosophy

This project **does not attempt** to solve:
- adversarial tampering
- ransomware
- controller firmware lies
- enterprise-scale storage problems

It **does** guarantee:
- no silent regeneration from corrupted data
- no automation-induced integrity loss
- predictable, explainable behavior

---

## Limitations (by design)

- Single-disk trust model
- Metadata-based change detection (not content hashes)
- Write-once or rarely modified data model
- HDD-first performance model (SSDs supported but not optimized)

---

## Final note

If this script ever refuses to regenerate PAR files, **that is intentional**.
It means integrity can no longer be proven safely.

At that point:
- stop
- investigate
- decide what you trust

Automation should never guess.
