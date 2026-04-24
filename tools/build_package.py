#!/usr/bin/env python3
"""
Mnema Package Builder

Builds a Mnema quiz package (.zip) from a source directory containing
data.json and optional images/ assets.

Usage:
    python build_package.py <source-dir> [output-dir]

Example:
    python build_package.py ./my-quiz ./output
    # Creates ./output/my-quiz.zip

The source directory must contain a 'data.json' file. Optional 'images/'
subdirectory will be included if present.
"""

import json
import os
import re
import sys
import zipfile
from pathlib import Path


def find_referenced_assets(data: dict) -> set:
    """Find all image paths referenced inside data.json."""
    assets = set()
    text = json.dumps(data, ensure_ascii=False)
    for match in re.finditer(r'!\[.*?\]\((images/[^)]+)\)', text):
        assets.add(match.group(1))
    return assets


def build_package(source_dir: str, output_dir: str) -> str:
    """
    Build a ZIP package from a source directory.

    Returns the path to the created ZIP file.
    """
    source = Path(source_dir).resolve()
    if not source.exists():
        raise FileNotFoundError(f"Source directory not found: {source}")
    if not source.is_dir():
        raise NotADirectoryError(f"Not a directory: {source}")

    data_json = source / "data.json"
    if not data_json.exists():
        raise FileNotFoundError(f"data.json not found in {source}")

    # Parse and validate basic structure
    with open(data_json, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, dict):
        raise ValueError("data.json must contain a JSON object")

    subject_name_en = data.get("subject_name_en")
    if not subject_name_en or not isinstance(subject_name_en, str):
        subject_name_en = source.name

    # Normalize to kebab-case if needed
    safe_name = re.sub(r'[^a-zA-Z0-9_-]', '-', subject_name_en).strip('-').lower()
    if not safe_name:
        safe_name = "package"

    # Determine output
    out = Path(output_dir).resolve()
    out.mkdir(parents=True, exist_ok=True)
    zip_path = out / f"{safe_name}.zip"

    # Find referenced assets
    referenced = find_referenced_assets(data)
    images_dir = source / "images"
    available_images = set()
    if images_dir.exists() and images_dir.is_dir():
        for f in images_dir.iterdir():
            if f.is_file():
                available_images.add(f"images/{f.name}")

    # Warn about missing images
    missing = referenced - available_images
    if missing:
        print(f"Warning: {len(missing)} referenced image(s) not found in images/:")
        for m in sorted(missing):
            print(f"  - {m}")

    # Build ZIP
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        # Add data.json
        zf.write(data_json, "data.json")

        # Add images
        added = 0
        if images_dir.exists() and images_dir.is_dir():
            for img_path in images_dir.iterdir():
                if img_path.is_file():
                    arc_name = f"images/{img_path.name}"
                    zf.write(img_path, arc_name)
                    added += 1

    size_kb = zip_path.stat().st_size / 1024
    print(f"Created: {zip_path}")
    print(f"  Size:     {size_kb:.1f} KB")
    print(f"  Images:   {added}")
    if missing:
        print(f"  Missing:  {len(missing)} image reference(s)")
    print()

    return str(zip_path)


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python build_package.py <source-dir> [output-dir]")
        print()
        print("Example:")
        print("  python build_package.py ./my-quiz ./output")
        return 2

    source_dir = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "."

    try:
        build_package(source_dir, output_dir)
        return 0
    except Exception as e:
        print(f"Error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
