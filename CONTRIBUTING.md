# Contributing

This project is intentionally small, conservative, and correctness-focused.

Contributions are welcome **only if they preserve or strengthen integrity guarantees**.

---

## Core invariant

Recovery data must never be regenerated unless existing data is proven clean.

Any change that weakens this rule will not be accepted.

---

## What is welcome

- Bug fixes improving correctness
- Safety and verification improvements
- Documentation clarifications
- Better error reporting

---

## What is not welcome

- Convenience over safety
- Silent fallback behavior
- Auto-regeneration after failed verification
- Clever heuristics that guess intent

---

## Coding guidelines

- Prefer explicit logic
- Avoid undocumented behavior
- Use Int64-safe math
- Fail loudly and clearly

---

## Final note

This project chooses **boring correctness** over clever automation.

If that philosophy resonates with you, contributions are welcome.
