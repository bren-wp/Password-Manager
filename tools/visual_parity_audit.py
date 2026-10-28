#!/usr/bin/env python3
"""Compare actual Flutter capture PNGs against the original user-provided ZIPs.

This is a diagnostic, NOT a certificate of pixel-perfect design parity.
Run after updating the actual screenshots. Requires: pip install Pillow.
Original references are supplied locally, never committed to a public repo.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
from zipfile import ZipFile

from PIL import Image, ImageChops, ImageFilter, ImageStat


def mean_absolute_rgb(reference, capture):
    difference = ImageChops.difference(reference, capture)
    return round(sum(ImageStat.Stat(difference).mean) / 3.0, 3)


def compare(archive, name, file):
    original = Image.open(io.BytesIO(archive.read(name))).convert("RGB")
    actual = Image.open(file).convert("RGB")
    ref_size = original.size
    actual_size = actual.size
    same_size = ref_size == actual_size
    # A scaled preview can help find broad UI mistakes, but is never called
    # an exact 1:1 match if original pixel dimensions differ.
    normalized = actual if same_size else actual.resize(
        ref_size, resample=Image.Resampling.LANCZOS)
    mae = mean_absolute_rgb(original, normalized)
    reference_edges = original.convert("L").filter(ImageFilter.FIND_EDGES)
    capture_edges = normalized.convert("L").filter(ImageFilter.FIND_EDGES)
    edge_mae = round(ImageStat.Stat(
        ImageChops.difference(reference_edges, capture_edges)).mean[0], 3)
    return {
        "name": Path(name).name,
        "reference_size": list(ref_size),
        "actual_size": list(actual_size),
        "native_size_match": same_size,
        "rgb_mean_absolute_error": mae,
        "edge_mean_absolute_error": edge_mae,
        "pixel_perfect": same_size and mae == 0,
    }


def scan(zips, capture_root):
    rows = []
    seen = {}
    for platform, zip_path in zips:
        with ZipFile(zip_path) as archive:
            names = sorted(n for n in archive.namelist()
                           if n.lower().endswith(".png"))
            for name in names:
                capture = capture_root / platform / Path(name).name
                if not capture.is_file():
                    rows.append({"name": Path(name).name, "platform": platform,
                                 "error": "Actual Flutter capture missing"})
                    continue
                result = compare(archive, name, capture)
                result["platform"] = platform
                signature = hashlib.sha256(capture.read_bytes()).hexdigest()
                previous = seen.get((platform, signature))
                if previous is not None:
                    result["error"] = f"Duplicate capture of {previous}"
                else:
                    seen[(platform, signature)] = result["name"]
                rows.append(result)
    return rows


def markdown(rows):
    output = [
        "# Veldigo — reference-to-Flutter pixel parity audit",
        "",
        "Exact 1:1 means **identical dimensions and every RGB pixel identical**. "
        "When dimensions differ, visual error is computed only after "
        "resampling; this is a diagnostic measure, not a pixel-perfect pass.",
        "",
        "| Platform | Screen | Reference | Flutter | RGB MAE | Edge MAE | Exact 1:1 |",
        "|---|---|---:|---:|---:|---:|:---:|",
    ]
    for item in rows:
        if "error" in item:
            output.append(f"| {item['platform']} | {item['name']} | "
                          f"— | — | — | — | FAIL ({item['error']}) |")
            continue
        ref = "×".join(map(str, item["reference_size"]))
        actual = "×".join(map(str, item["actual_size"]))
        output.append(
            f"| {item['platform']} | {item['name']} | {ref} | {actual} | "
            f"{item['rgb_mean_absolute_error']} | "
            f"{item['edge_mean_absolute_error']} | "
            f"{'YES' if item['pixel_perfect'] else 'NO'} |")
    total = len(rows)
    exact = sum(1 for item in rows if item.get("pixel_perfect"))
    duplicated = sum(1 for item in rows if "Duplicate" in item.get("error", ""))
    output += ["", f"Compared: **{total}**, exact: **{exact}**, "
               f"duplicate captures: **{duplicated}**.",
               "", "A screenshot pass does not replace functional tests, "
               "real-device testing, or security review."]
    return "\n".join(output) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--android-zip", type=Path, required=True)
    parser.add_argument("--windows-zip", type=Path, required=True)
    parser.add_argument("--actual", type=Path,
                        default=Path("assets/screenshots"))
    parser.add_argument("--report", type=Path,
                        default=Path("build/veldigo-pixel-parity.md"))
    parser.add_argument("--json", type=Path,
                        default=Path("build/veldigo-pixel-parity.json"))
    args = parser.parse_args()
    rows = scan([("android", args.android_zip),
                 ("windows", args.windows_zip)], args.actual)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.json.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(markdown(rows), encoding="utf-8")
    args.json.write_text(json.dumps(rows, ensure_ascii=False, indent=2),
                         encoding="utf-8")
    print(f"Compared {len(rows)} screens: "
          f"{sum(bool(x.get('pixel_perfect')) for x in rows)} exact.")
    print(f"Markdown report: {args.report}")
    print(f"JSON report: {args.json}")
    if any("error" in row for row in rows):
        raise SystemExit("Missing or duplicated screenshots detected.")


if __name__ == "__main__":
    main()
