# Changelog

All notable changes to this project will be documented in this file.

This project follows a **pragmatic changelog** approach:
- Only meaningful, user-visible changes are recorded
- Internal refactors without behavioral impact are not listed
- Correctness and safety changes take priority over features

---

## [1.0.0]

### Added
- Automated per-directory PAR2 creation for HDD-based storage
- Mixed-content directory handling (large + small files)
- Metadata-based change detection (`recovery.sha256`)
- Standalone verification script (`par.verify.ps1`)
- Filename normalization helper (`fix.filenames.ps1`)
- Dedicated `.recovery` subdirectory layout

### Changed
- Switched PAR2 engine to **MultiPar (`par2j64.exe`)**
- Introduced persistent structural padding for very small datasets
- Verification semantics aligned strictly with MultiPar behavior

### Safety / Integrity
- **Mandatory PAR2 verification before regeneration**
- Regeneration is blocked if verification fails
- Prevents locking corrupted data as a new recovery baseline
- Explicit failure instead of silent guessing

### Design decisions
- Sequential, archive-friendly I/O
- Int64-safe math for very large files
- Explicit exclusion of OS junk and metadata files
- No reliance on undocumented filesystem behavior

---

## Versioning notes

- Version **1.0.0** represents a **stable, integrity-correct baseline**
- Future versions increment only if:
  - behavior changes
  - safety guarantees are strengthened
  - or new operating modes are added

Cosmetic changes alone do not warrant a version bump.

---

## Philosophy

If a future change ever weakens the integrity guarantees described in the README,
it will be considered a **breaking change** and versioned accordingly.

Automation should never guess.
