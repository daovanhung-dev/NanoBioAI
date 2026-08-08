# Stitch imported asset policy

- `manifest.json` is the source-of-truth inventory for remote image references
  extracted from the 76 Stitch HTML prototypes.
- Network access is permitted only while running the controlled importer. The
  application must never load the recorded source URLs at runtime.
- Every imported item starts with `license_status: unverified` and
  `runtime_eligible: false`. A separate legal/design review is required before
  any item can become a production asset.
- Until verification, use an existing bundled Nabi/domain asset, user initials,
  real runtime media, or a neutral local placeholder.
- Prototype names, health readings, financial values, avatars and QR payloads
  are visual references, not production seed data.
