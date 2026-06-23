from __future__ import annotations
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
manifest_path = ROOT / 'assets/config/Nabi/Nabi_asset_manifest.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
assets = manifest['assets']
assert len(assets) == 84, f'Expected 84 asset manifest entries, got {len(assets)}'
seen = set()
for item in assets:
    path = ROOT / item['path']
    assert path.exists(), f'Missing: {item["path"]}'
    assert path.suffix.lower() == '.png', f'Not PNG: {item["path"]}'
    assert item['path'] not in seen, f'Duplicate path: {item["path"]}'
    seen.add(item['path'])
    im = Image.open(path)
    assert im.mode == 'RGBA', f'Asset must be RGBA: {item["path"]}, got {im.mode}'
    assert im.size == (512, 512), f'Expected 512x512: {item["path"]}, got {im.size}'
    alpha = im.getchannel('A')
    alpha_min, alpha_max = alpha.getextrema()
    assert alpha_min == 0 and alpha_max == 255, f'Asset must have transparent and opaque pixels: {item["path"]}'
print(f'OK: {len(assets)} Nabi assets validated.')
