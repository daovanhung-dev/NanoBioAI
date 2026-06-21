# V3 App Version

V3 is the planned Plus and FamilyPlus layer. It inherits from v2 at the product
level, but features must still keep clean boundaries and must not import lower
version presentation or controller code directly.

Current status:

- `app/` and `router/` exist as a compile-safe shell.
- `features/` contains placeholders for planned Plus and FamilyPlus modules.
- No paid feature is wired into production flow until a matching BD/DD exists.

Guardrails:

- Plus extends Free by removing the Free AI chat and schedule generation quotas.
- FamilyPlus extends Plus with family members, family onboarding, and member
  schedule visibility.
- Membership state must come from Supabase or another trusted backend source.
- Do not implement payment, family sharing, or cross-user health access from
  client-only flags.
