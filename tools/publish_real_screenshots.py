#!/usr/bin/env python3
"""Publish genuine golden captures of Veldigo Flutter widgets in README.

The images are rendered by Flutter's test engine using demo-only records;
the script never substitutes illustrations, mockups, or user secrets.
"""
from pathlib import Path
import hashlib
import shutil
import struct

root = Path(__file__).resolve().parents[1]
origin = root / "tool" / "goldens" / "marketing"
destination = root / "assets" / "screenshots"
readme = root / "README.md"

android = [
    "01_Glavni_trezor",
    "02_Postavljanje_glavne_lozinke",
    "03_Otkljucavanje",
    "04_Dodavanje_lozinke",
    "05_Detalji_lozinke",
    "06_Generator_lozinki",
    "07_Sigurnosni_centar",
    "08_Sigurne_biljeske",
    "09_Autentifikator_TOTP",
    "10_Postavke",
    "11_Kategorije",
    "12_Sigurnosna_kopija",
    "13_Kartice",
    "14_Uvodni_ekran",
    "15_Dobrodoslica",
]
windows = [
    "01_Glavni_trezor",
    "02_Otkljucavanje",
    "03_Dodavanje_lozinke",
    "04_Generator_lozinki",
    "05_Sigurnosni_centar",
    "06_Sigurne_biljeske",
    "07_Postavke",
    "08_Sigurnosna_kopija",
    "09_Autentifikator",
    "10_Kategorije",
    "11_Prvo_postavljanje",
]

# Physical sizes from the original Veldigo reference ZIP archives.
# Compare the PNG IHDR rather than trusting screenshot test configuration.
android_dimensions = {
    "01_Glavni_trezor": (843, 1866),
    "02_Postavljanje_glavne_lozinke": (887, 1774),
    "03_Otkljucavanje": (887, 1774),
    "04_Dodavanje_lozinke": (864, 1821),
    "05_Detalji_lozinke": (862, 1824),
    "06_Generator_lozinki": (887, 1774),
    "07_Sigurnosni_centar": (841, 1870),
    "08_Sigurne_biljeske": (887, 1774),
    "09_Autentifikator_TOTP": (862, 1825),
    "10_Postavke": (863, 1823),
    "11_Kategorije": (832, 1856),
    "12_Sigurnosna_kopija": (832, 1856),
    "13_Kartice": (832, 1856),
    "14_Uvodni_ekran": (832, 1856),
    "15_Dobrodoslica": (832, 1856),
}
windows_dimensions = {
    **{name: (1586, 992) for name in windows[:4]},
    **{name: (1536, 1024) for name in windows[4:]},
}


def image_dimensions(path):
    with path.open("rb") as source:
        header = source.read(24)
    if len(header) != 24 or header[:8] != bytes.fromhex("89504e470d0a1a0a"):
        raise SystemExit(f"Invalid PNG file: {path}")
    return struct.unpack(">II", header[16:24])


missing = [
    str(origin / platform / (name + ".png"))
    for platform, names in [("android", android), ("windows", windows)]
    for name in names
    if not (origin / platform / (name + ".png")).is_file()
]
if missing:
    raise SystemExit("Not all 26 real UI screenshots were captured:\n" +
                     "\n".join(missing))

for platform, targets in [
    ("android", android_dimensions), ("windows", windows_dimensions)
]:
    for name, expected in targets.items():
        captured = origin / platform / (name + ".png")
        actual = image_dimensions(captured)
        if actual != expected:
            raise SystemExit(
                f"Wrong {platform} screenshot resolution: {name}: "
                f"expected {expected}, captured {actual}. "
                "Regenerate the actual Flutter view at the exact reference "
                "physical pixel dimensions."
            )

# Every separately named screen must be genuinely different.
# In particular, vault-home and account-detail had previously been committed
# as byte-identical screenshots, hiding a failed detail capture.
for platform, names in [("android", android), ("windows", windows)]:
    seen = {}
    for name in names:
        source = origin / platform / (name + ".png")
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        if digest in seen:
            raise SystemExit(
                f"Duplicate {platform} screenshot: {seen[digest]} and {name}. "
                "Fix the Flutter capture/navigation instead of publishing "
                "the same image for two screens."
            )
        seen[digest] = name

for platform, names in [("android", android), ("windows", windows)]:
    folder = destination / platform
    folder.mkdir(parents=True, exist_ok=True)
    for name in names:
        source = origin / platform / (name + ".png")
        if source.stat().st_size < 500:
            raise SystemExit(f"Suspicious empty screenshot: {source}")
        shutil.copy2(source, folder / source.name)

text = readme.read_text(encoding="utf-8")
text = text.replace(
    '<img src="assets/showcase/android.svg" alt="Veldigo Android trezor — vizualni prikaz" width="300" />',
    '<img src="assets/screenshots/android/01_Glavni_trezor.png" alt="Veldigo Android: stvarni Flutter prikaz trezora" width="300" />',
).replace(
    '<img src="assets/showcase/windows.svg" alt="Veldigo Windows trezor — vizualni prikaz" width="650" />',
    '<img src="assets/screenshots/windows/01_Glavni_trezor.png" alt="Veldigo: stvarni Flutter prikaz Windows rasporeda" width="650" />',
)
begin = "<!-- ACTUAL_SCREENSHOTS_START -->"
end = "<!-- ACTUAL_SCREENSHOTS_END -->"
gallery = [
    "## Svaki zaslon. Uvijek pod kontrolom.",
    "",
    "Istražite svih **15 Android** i **11 Windows** zaslona Veldiga.",
    "Snimke prikazuju stvarno Veldigo sučelje s demonstracijskim podacima.",
    "",
]
for platform, names, title, width in [
    ("android", android, "Android — 15 zaslona", 300),
    ("windows", windows, "Windows — 11 zaslona", 680),
]:
    gallery += [f"<details>", f"<summary><strong>{title}</strong></summary>", ""]
    for name in names:
        label = name[3:].replace("_", " ").replace("TOTP", "TOTP")
        gallery += [f"**{label}**", "",
                    f'<img src="assets/screenshots/{platform}/{name}.png" alt="Veldigo {platform}: {label}" width="{width}" />',
                    ""]
    gallery += ["</details>", ""]
block = "\n".join(gallery)
if begin in text and end in text:
    a = text.index(begin)
    b = text.index(end, a) + len(end)
    text = text[:a] + begin + "\n" + block + "\n" + end + text[b:]
else:
    anchor = "## Sve važno na jednom mjestu"
    if anchor not in text:
        raise SystemExit("README insertion point missing")
    text = text.replace(anchor, begin + "\n" + block + "\n" + end +
                        "\n\n" + anchor, 1)
readme.write_text(text, encoding="utf-8")
print("Published 15 Android + 11 Windows actual Flutter UI screenshots.")
