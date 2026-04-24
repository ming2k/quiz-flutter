#!/usr/bin/env python3
"""
Mnema Package Validator

Validates a Mnema quiz package (.zip, .quizpkg, or .mnemapkg) against
the Package Protocol 2.0 specification.

Usage:
    python validate_package.py <path-to-package.zip>
    python validate_package.py --strict <path-to-package.zip>

Exit codes:
    0 - Package is valid
    1 - Validation errors found
    2 - File or system error
"""

import json
import re
import sys
import zipfile
from pathlib import Path
from typing import List, Optional

SUPPORTED_TYPES = {
    "multiple_choice",
    "true_false",
    "fill_blank",
    "cloze",
    "flashcard",
    "passage",
}

SUPPORTED_IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp"}


def _find_image_refs(text: str) -> List[str]:
    """Find all Markdown image references pointing to images/."""
    return re.findall(r"!\[.*?\]\((images/[^)]+)\)", text)


def _validate_question(
    q: dict,
    path: str,
    errors: List[str],
    warnings: List[str],
    strict: bool = False,
) -> None:
    content = q.get("content")
    if not content or not isinstance(content, str) or not content.strip():
        errors.append(f"{path}: Missing or empty 'content'")

    q_type = q.get("question_type")
    sub_questions = q.get("questions")
    has_sub = isinstance(sub_questions, list) and len(sub_questions) > 0

    if q_type is None:
        q_type = "passage" if has_sub else "multiple_choice"

    if q_type not in SUPPORTED_TYPES:
        errors.append(f'{path}: Unsupported question_type "{q_type}"')

    requires_choices = q_type in ("multiple_choice", "true_false")
    requires_answer = q_type != "passage" and not has_sub

    if requires_choices and not has_sub:
        choices = q.get("choices")
        if not isinstance(choices, list) or len(choices) == 0:
            errors.append(f"{path}: {q_type} question missing 'choices'")
        else:
            for ci, c in enumerate(choices):
                if not isinstance(c, dict):
                    errors.append(f"{path} choice[{ci}]: Expected object, got {type(c).__name__}")
                    continue
                if "key" not in c:
                    errors.append(f"{path} choice[{ci}]: Missing 'key'")
                content_fields = [f for f in ("content", "html", "text") if f in c]
                if not content_fields:
                    errors.append(f"{path} choice[{ci}]: Missing 'content' (or 'html'/'text')")

            answer = q.get("answer")
            if not answer or not isinstance(answer, str):
                errors.append(f"{path}: {q_type} question missing 'answer'")
            else:
                choice_keys = set()
                for c in choices:
                    if isinstance(c, dict):
                        key = str(c.get("key", "")).upper()
                        choice_keys.add(key)
                if answer.upper() not in choice_keys:
                    errors.append(
                        f'{path}: Answer "{answer}" does not match any choice key'
                    )
    elif requires_answer:
        answer = q.get("answer")
        if not answer or not isinstance(answer, str) or not answer.strip():
            errors.append(f"{path}: {q_type} question missing 'answer'")

    difficulty = q.get("difficulty")
    if difficulty is not None:
        if not isinstance(difficulty, (int, float)):
            errors.append(f"{path}: 'difficulty' must be a number")
        elif difficulty < 1.0 or difficulty > 5.0:
            errors.append(f"{path}: 'difficulty' must be between 1.0 and 5.0")

    tags = q.get("tags")
    if tags is not None:
        if not isinstance(tags, list):
            errors.append(f"{path}: 'tags' must be an array of strings")
        else:
            for ti, tag in enumerate(tags):
                if not isinstance(tag, str):
                    errors.append(f"{path} tag[{ti}]: Must be a string")
                elif len(tag) > 50:
                    warnings.append(f"{path} tag[{ti}]: Exceeds 50 characters")
            if strict and len(tags) > 10:
                warnings.append(f"{path}: More than 10 tags (recommended max is 10)")

    if has_sub:
        for i, sq in enumerate(sub_questions):
            if not isinstance(sq, dict):
                errors.append(f"{path}.subQ{i}: Expected object, got {type(sq).__name__}")
                continue
            _validate_question(sq, f"{path}.subQ{i}", errors, warnings, strict)


def _validate_data(
    data: dict,
    raw_text: str,
    errors: List[str],
    warnings: List[str],
    stats: dict,
    strict: bool = False,
    zip_names: Optional[List[str]] = None,
) -> None:
    """Validate parsed data.json content."""
    if not isinstance(data, dict):
        errors.append("Top-level JSON must be an object")
        return

    protocol_version = data.get("protocol_version", "1.0")
    if protocol_version not in ("1.0", "2.0"):
        warnings.append(f"Unknown protocol_version: {protocol_version}")

    subject_name_zh = data.get("subject_name_zh")
    if not subject_name_zh or not isinstance(subject_name_zh, str) or not subject_name_zh.strip():
        errors.append("Missing or empty 'subject_name_zh'")

    subject_name_en = data.get("subject_name_en")
    if not subject_name_en or not isinstance(subject_name_en, str) or not subject_name_en.strip():
        errors.append("Missing or empty 'subject_name_en'")
    elif strict:
        if not re.match(r"^[a-z0-9]+(-[a-z0-9]+)*$", subject_name_en):
            warnings.append(
                f"'subject_name_en' '{subject_name_en}' should be lowercase kebab-case "
                "(e.g., 'ship-management')"
            )

    chapters = data.get("chapters")
    if not isinstance(chapters, list) or len(chapters) == 0:
        errors.append("Missing or empty 'chapters' array")
        return

    stats["chapters"] = len(chapters)

    # Collect image references
    image_refs = set(_find_image_refs(raw_text))
    stats["images_in_data"] = len(image_refs)

    # Check image files exist (if zip_names provided)
    if zip_names is not None:
        for ref in image_refs:
            if ref not in zip_names:
                alt = ref.replace("images/", "")
                alt_candidates = [n for n in zip_names if n.endswith(alt) and not n.startswith("__MACOSX")]
                if not alt_candidates:
                    errors.append(f"Missing image file referenced in data: {ref}")
                    stats["missing_images"] += 1
            else:
                ext = Path(ref).suffix.lower()
                if ext not in SUPPORTED_IMAGE_EXTS:
                    warnings.append(f"Non-standard image extension: {ref}")

        stats["images_in_zip"] = len(
            [n for n in zip_names if n.startswith("images/") and not n.endswith("/")]
        )

    # Validate structure
    for ci, chapter in enumerate(chapters):
        if not isinstance(chapter, dict):
            errors.append(f"Chapter[{ci}]: Expected object, got {type(chapter).__name__}")
            continue

        title = chapter.get("title")
        if not title or not isinstance(title, str) or not title.strip():
            errors.append(f"Chapter[{ci}]: Missing or empty 'title'")

        sections = chapter.get("sections")
        if not isinstance(sections, list) or len(sections) == 0:
            errors.append(f"Chapter[{ci}]: Missing or empty 'sections'")
            continue

        stats["sections"] += len(sections)

        for si, section in enumerate(sections):
            if not isinstance(section, dict):
                errors.append(f"Chapter[{ci}] Section[{si}]: Expected object")
                continue

            s_title = section.get("title")
            if not s_title or not isinstance(s_title, str) or not s_title.strip():
                errors.append(f"Chapter[{ci}] Section[{si}]: Missing or empty 'title'")

            questions = section.get("questions")
            if not isinstance(questions, list):
                continue

            for qi, q in enumerate(questions):
                if not isinstance(q, dict):
                    errors.append(f"Chapter[{ci}] Section[{si}] Question[{qi}]: Expected object")
                    continue
                _validate_question(q, f"C{ci}.S{si}.Q{qi}", errors, warnings, strict)
                stats["questions"] += _count_questions(q)
                stats["answerable_questions"] += _count_answerable(q)


def validate_package(package_path: str, strict: bool = False) -> dict:
    """
    Validate a package file (ZIP) or a raw data.json file.

    Returns a dict with keys:
        - valid (bool)
        - errors (List[str])
        - warnings (List[str])
        - stats (dict)
    """
    errors: List[str] = []
    warnings: List[str] = []
    stats = {
        "chapters": 0,
        "sections": 0,
        "questions": 0,
        "answerable_questions": 0,
        "images_in_data": 0,
        "images_in_zip": 0,
        "missing_images": 0,
    }

    path = Path(package_path)
    if not path.exists():
        return {"valid": False, "errors": [f"File not found: {package_path}"], "warnings": [], "stats": stats}

    if not path.is_file():
        return {"valid": False, "errors": [f"Not a file: {package_path}"], "warnings": [], "stats": stats}

    is_json = path.suffix.lower() == ".json"

    try:
        if is_json:
            # Validate raw JSON file
            with open(path, "r", encoding="utf-8") as f:
                raw = f.read()
            try:
                data = json.loads(raw)
            except json.JSONDecodeError as e:
                errors.append(f"Invalid JSON: {e}")
                return {"valid": False, "errors": errors, "warnings": warnings, "stats": stats}
            _validate_data(data, raw, errors, warnings, stats, strict, zip_names=None)
        else:
            # Validate ZIP package
            with zipfile.ZipFile(path, "r") as zf:
                names = zf.namelist()

                if "data.json" not in names:
                    data_json_candidates = [n for n in names if n.endswith("data.json") and not n.startswith("__MACOSX")]
                    if not data_json_candidates:
                        errors.append("Missing data.json in package")
                        return {"valid": False, "errors": errors, "warnings": warnings, "stats": stats}
                    data_json_path = data_json_candidates[0]
                    warnings.append(f"data.json found at nested path: {data_json_path}")
                else:
                    data_json_path = "data.json"

                try:
                    raw = zf.read(data_json_path).decode("utf-8")
                    data = json.loads(raw)
                except json.JSONDecodeError as e:
                    errors.append(f"Invalid JSON in {data_json_path}: {e}")
                    return {"valid": False, "errors": errors, "warnings": warnings, "stats": stats}
                except UnicodeDecodeError as e:
                    errors.append(f"File is not valid UTF-8: {e}")
                    return {"valid": False, "errors": errors, "warnings": warnings, "stats": stats}

                _validate_data(data, raw, errors, warnings, stats, strict, zip_names=names)

    except zipfile.BadZipFile:
        errors.append("File is not a valid ZIP archive")
    except Exception as e:
        errors.append(f"Unexpected error: {e}")

    return {
        "valid": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "stats": stats,
    }


def _count_questions(q: dict) -> int:
    """Count total questions including sub-questions."""
    sub = q.get("questions")
    if isinstance(sub, list) and sub:
        return 1 + sum(_count_questions(sq) for sq in sub)
    return 1


def _count_answerable(q: dict) -> int:
    """Count answerable questions (non-passage)."""
    q_type = q.get("question_type")
    sub = q.get("questions")
    has_sub = isinstance(sub, list) and sub
    if q_type is None:
        q_type = "passage" if has_sub else "multiple_choice"

    count = 0
    if q_type != "passage":
        count += 1

    if has_sub:
        for sq in sub:
            if isinstance(sq, dict):
                count += _count_answerable(sq)

    return count


def main() -> int:
    args = sys.argv[1:]
    strict = False
    if "--strict" in args:
        strict = True
        args.remove("--strict")

    if not args:
        print("Usage: python validate_package.py [--strict] <path-to-package.zip>")
        return 2

    package_path = args[0]
    result = validate_package(package_path, strict=strict)

    print(f"Package: {package_path}")
    print(f"Status:  {'VALID' if result['valid'] else 'INVALID'}")
    print()

    stats = result["stats"]
    print("Statistics:")
    print(f"  Chapters:           {stats['chapters']}")
    print(f"  Sections:           {stats['sections']}")
    print(f"  Total questions:    {stats['questions']}")
    print(f"  Answerable:         {stats['answerable_questions']}")
    print(f"  Images referenced:  {stats['images_in_data']}")
    print(f"  Images in package:  {stats['images_in_zip']}")
    print(f"  Missing images:     {stats['missing_images']}")
    print()

    if result["warnings"]:
        print(f"Warnings ({len(result['warnings'])}):")
        for w in result["warnings"]:
            print(f"  [W] {w}")
        print()

    if result["errors"]:
        print(f"Errors ({len(result['errors'])}):")
        for e in result["errors"]:
            print(f"  [E] {e}")
        return 1

    print("No errors found. Package is ready for distribution.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
