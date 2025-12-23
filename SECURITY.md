# Security Policy

This document explains the **security scope** of this project.

---

## Supported use cases

This project is designed for:
- Home and consumer users
- Offline HDD or SSD storage
- External and removable disks
- Non-adversarial environments

It assumes:
- a trusted local system
- a trusted operating system
- a trusted user

---

## Threat model

This project helps protect against:
- silent data corruption (bitrot)
- accidental file damage
- unsafe automation behavior

Primary goal:

Prevent irreversible data loss caused by automation logic.

---

## Out of scope

This project does not protect against:
- malware or ransomware
- adversarial tampering
- firmware-level deception
- supply-chain attacks

---

## Reporting issues

If you believe you found an issue that:
- weakens integrity guarantees
- introduces silent failure
- bypasses verification-before-regeneration

Contact:

Miroslaw Marcinkowski  
mireksson@gmail.com

---

## Final note

Unsafe automation is treated as a security issue.

Convenience is never allowed to override correctness.
