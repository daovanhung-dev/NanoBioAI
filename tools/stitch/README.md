# Stitch asset importer

`import_assets.py` scans every `code.html` under the Stitch design handoff,
downloads only allowlisted HTTPS image references, verifies the response and
writes deterministic local files plus a provenance manifest.

Run from the repository root and write the generated manifest to a temporary
location for review:

```powershell
python tools/stitch/import_assets.py `
  --manifest-output "$env:TEMP/nanobio-stitch-manifest.json"
```

The committed manifest is `assets/config/stitch/manifest.json`. Imported files
are reference-only while `license_status` is `unverified`; application code must
use a licensed bundled asset or a data-driven placeholder instead. Source URLs
are retained only for provenance and must never be used as runtime hotlinks.

Validate the registry, manifest, source hashes and every local file without
network access:

```powershell
python tools/stitch/validate_registry.py
```
