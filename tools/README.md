# Mnema Package Tools

This directory contains command-line tools for creating, validating, and converting Mnema quiz packages.

## Available Tools

### `validate_package.py`

Validates a package (ZIP archive or raw `data.json`) against the Mnema Package Protocol 2.0 specification.

```bash
# Validate a raw data.json file (useful during authoring)
python tools/validate_package.py path/to/data.json

# Validate a finished ZIP package
python tools/validate_package.py path/to/package.zip

# Strict mode: enforce naming conventions and best-practice limits
python tools/validate_package.py --strict path/to/package.zip
```

**What it checks**:
- Required top-level fields (`subject_name_zh`, `subject_name_en`, `chapters`)
- Chapter / section / question structure
- Question type validity and required fields
- Answer matches a choice key (for choice-based questions)
- Image references resolve to files in the package
- Difficulty range (1.0–5.0)
- Tag format (string array, max 50 chars per tag)
- Strict mode additionally checks `subject_name_en` is kebab-case

**Exit codes**:
- `0` - Valid
- `1` - Validation errors
- `2` - File or usage error

---

### `build_package.py`

Builds a `.zip` package from a source directory containing `data.json` and optional `images/`.

```bash
# Basic usage
python tools/build_package.py <source-dir>

# Specify output directory
python tools/build_package.py <source-dir> <output-dir>
```

**Example**:

```bash
python tools/build_package.py examples/minimal-package ./output
# Creates: ./output/example-subject.zip
```

**Directory structure expected**:

```
source-dir/
├── data.json          (required)
└── images/            (optional)
    └── ...
```

The tool will:
1. Read and parse `data.json`
2. Detect image references inside the JSON
3. Warn about any referenced images missing from `images/`
4. Produce a flat ZIP with `data.json` and `images/*` at the root

---

### `create_packages.py` (Internal)

Creates optimized ZIP packages from existing JSON files, copying only referenced assets.

> **Note**: This script has hardcoded paths for the project's internal data pipeline. It is not intended for general community use.

---

### `convert_to_packages.py` (Internal)

Converts flat JSON quiz data (with separate `book`, `chapters`, `sections`, `questions` arrays) into the nested Package Protocol format.

> **Note**: This script has hardcoded paths for the project's internal data pipeline. It is not intended for general community use.

---

## Requirements

All tools require **Python 3.8+** and use only the standard library.

No additional packages need to be installed.

## Workflow for Package Creators

1. **Author** your questions in `data.json`
2. **Validate** with `validate_package.py data.json`
3. **Build** with `build_package.py <dir> <output>`
4. **Re-validate** the ZIP with `validate_package.py <output>.zip`
5. **Share** the `.zip` file

See [`docs/package_creator_guide.md`](../docs/package_creator_guide.md) for a full authoring tutorial.
