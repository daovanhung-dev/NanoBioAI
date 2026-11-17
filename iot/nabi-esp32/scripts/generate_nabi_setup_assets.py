#!/usr/bin/env python3
"""Generate the small RGB565 image and embed the matching PNG in the Wi-Fi portal."""

from __future__ import annotations

import base64
from pathlib import Path
import re

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "main/assets/nabi_setup.png"
RGB565_OUTPUT = ROOT / "main/assets/nabi_setup.rgb565"
PORTAL_FILES = (
    ROOT / "third_party/esp-wifi-connect/assets/wifi_configuration.html",
    ROOT / "third_party/esp-wifi-connect/assets/wifi_configuration_done.html",
)
IMAGE_URI = "data:image/png;base64,{}"
RGB565_BACKGROUND = (244, 247, 251)


def make_rgb565_image(image: Image.Image) -> bytes:
    image = image.convert("RGBA").resize((128, 128), Image.Resampling.LANCZOS)
    background = Image.new("RGBA", image.size, (*RGB565_BACKGROUND, 255))
    image = Image.alpha_composite(background, image).convert("RGB")
    raw = bytearray()
    for red, green, blue in image.get_flattened_data():
        pixel = ((red & 0xF8) << 8) | ((green & 0xFC) << 3) | (blue >> 3)
        raw.extend((pixel & 0xFF, pixel >> 8))
    return bytes(raw)


def embed_portal_image(data_uri: str) -> None:
    for path in PORTAL_FILES:
        html = path.read_text(encoding="utf-8")
        html, replacements = re.subn(
            r'src="(?:__NABI_SETUP_IMAGE__|data:image/png;base64,[^"]+)"',
            f'src="{data_uri}"',
            html,
        )
        if replacements == 0:
            raise RuntimeError(f"No Nabi image placeholder found in {path}")
        path.write_text(html, encoding="utf-8")


def main() -> None:
    image_bytes = SOURCE.read_bytes()
    with Image.open(SOURCE) as image:
        if image.size != (128, 128):
            raise ValueError(f"Expected a 128x128 source image, got {image.size}")
        RGB565_OUTPUT.write_bytes(make_rgb565_image(image))
    embed_portal_image(IMAGE_URI.format(base64.b64encode(image_bytes).decode("ascii")))
    print(f"Generated {RGB565_OUTPUT.relative_to(ROOT)} and embedded Nabi art in portal pages")


if __name__ == "__main__":
    main()
