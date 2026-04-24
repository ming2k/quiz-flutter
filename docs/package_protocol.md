# Mnema Package Protocol Specification

> **Version**: 2.0  
> **Last Updated**: 2026-04-24  
> **Target Audience**: Package creators, content providers, and third-party tooling developers.

---

## 1. Overview

A **Package** is a self-contained ZIP archive that contains exam questions, metadata, and optional media assets. The app imports Packages to populate its local SQLite database.

### File Extension
- **Standard**: `.zip`
- **Alternative**: `.quizpkg` or `.mnemapkg` (treated identically by the app)

### Package Structure

```
{package-name}.zip
├── data.json          (required)
└── images/            (optional)
    ├── {hash1}.png
    ├── {hash2}.jpg
    └── ...
```

- **`data.json`**: The primary data file. Must be valid UTF-8 JSON.
- **`images/`**: Optional directory containing media referenced by questions. Images are referenced from `data.json` via Markdown syntax: `![alt](images/filename.png)`.

---

## 2. Protocol Version

The top-level JSON object **SHOULD** include a `protocol_version` field. If omitted, the app assumes `"1.0"`.

```json
{
  "protocol_version": "2.0",
  ...
}
```

| Version | Description |
|---------|-------------|
| `1.0` | Original format. Supports `chapters → sections → questions` with `content`, `choices`, `answer`, `explanation`. |
| `2.0` | Adds optional fields: `tags`, `difficulty`, `note`, `question_type`, `front_template`, `back_template`, and explicit passage/sub-question modeling. |

**Backward Compatibility**: Apps implementing Protocol 2.0 **MUST** accept Packages without the new optional fields. Apps implementing Protocol 1.0 **SHOULD** ignore unknown fields rather than failing.

---

## 3. Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `protocol_version` | `string` | No | Package format version. Defaults to `"1.0"`. |
| `subject_name_zh` | `string` | **Yes** | Display name in Chinese (e.g., "船舶管理"). |
| `subject_name_en` | `string` | **Yes** | Machine identifier in English (e.g., "ship-management"). Used for filenames and internal IDs. |
| `chapters` | `array` | **Yes** | Ordered list of chapters. Must contain at least one chapter. |

---

## 4. Chapter Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | `string` | **Yes** | Chapter title displayed to users. |
| `sections` | `array` | **Yes** | Ordered list of sections within this chapter. |

---

## 5. Section Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | `string` | **Yes** | Section title displayed to users. |
| `questions` | `array` | **Yes** | List of questions in this section. |

---

## 6. Question Object

### 6.1 Required Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `content` | `string` | **Yes** | The question stem. Supports **Markdown** and **LaTeX** (MathJax syntax: `$...$` for inline, `$$...$$` for display). |
| `choices` | `array` | **Yes*** | List of choice objects (see 6.2). *Required for `multiple_choice` and `true_false` types.* |
| `answer` | `string` | **Yes** | The correct answer. For multiple choice, this is the choice `key` (e.g., `"A"`). For flashcards, this can be the back content or a key referencing it. |
| `explanation` | `string` | No | Detailed explanation shown after answering. Supports Markdown and LaTeX. |

### 6.2 Choice Object

Each item in `choices` is an object with:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `key` | `string` | **Yes** | Choice identifier (e.g., `"A"`, `"B"`, `"C"`, `"D"`). |
| `content` | `string` | **Yes*** | Choice text. Supports Markdown and LaTeX. |
| `html` | `string` | **Yes*** | Alternative to `content`. Used when choice text contains rich HTML. |
| `text` | `string` | **Yes*** | Alternative to `content`. Used by some legacy tooling. |

\* One of `content`, `html`, or `text` must be present. The app resolves them in priority order: `content` > `html` > `text`.

**Alternative format** (backward compatible): A single-entry map `{"A": "Choice text"}` is also accepted.

### 6.3 Optional Fields (Protocol 2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `question_type` | `string` | No | Question type. Values: `"multiple_choice"` (default), `"true_false"`, `"fill_blank"`, `"cloze"`, `"flashcard"`, `"passage"`. |
| `tags` | `array<string>` | No | Tags for categorization (e.g., `["SOLAS", "公约", "安全"]`), max 10 tags recommended. |
| `difficulty` | `number` | No | Difficulty rating. Range: `1.0` (easiest) to `5.0` (hardest). Default: `2.5`. |
| `note` | `string` | No | User-facing or creator note. Supports Markdown. |
| `front_template` | `string` | No | For `flashcard` type: custom template for the front side. If omitted, `content` is used. |
| `back_template` | `string` | No | For `flashcard` type: custom template for the back side. If omitted, `answer` + `explanation` is used. |
| `questions` | `array` | No | **Nested sub-questions** for reading comprehension passages. When present, the parent question is a passage and these are its sub-questions. Each sub-question follows the same Question schema. |

### 6.4 Supported Question Types

| Type | Required Fields | Current Runtime Behavior |
|------|-----------------|--------------------------|
| `multiple_choice` | `content`, `choices`, `answer` | Fully supported in Practice, Test, and Review. |
| `true_false` | `content`, two choices, `answer` | Treated as a choice-based question. |
| `fill_blank` | `content`, `answer` | Imported and shown as answer-reveal content in Review. Dedicated typed input is not yet implemented. |
| `cloze` | `content`, `answer` | Imported and shown as answer-reveal content in Review. Dedicated cloze interaction is not yet implemented. |
| `flashcard` | `content` or `front_template`, `answer` or `back_template` | Imported and shown as answer-reveal content in Review. |
| `passage` | `content`, `questions` | Stored as shared context. It is not counted as an answerable item. |

Practice and Test modes currently require choice-based, auto-gradable questions. Review mode can schedule any imported item with a non-empty `answer`.

### 6.5 Nested Questions (Reading Comprehension)

A question may contain a `questions` array representing sub-questions tied to a shared passage:

```json
{
  "content": "Read the following passage about SOLAS...",
  "questions": [
    {
      "content": "According to the passage, SOLAS was first adopted in:",
      "choices": [...],
      "answer": "A"
    }
  ]
}
```

- The parent question (passage) **does not** have `choices` or `answer` at its own level.
- Set `question_type` to `"passage"` for clarity. Older packages may omit it when `questions` is present.
- Sub-questions **must** have `choices` and `answer`.
- The app renders the parent `content` as shared context above each sub-question.

---

## 7. Media Assets

### 7.1 Images

- **Location**: `images/` directory inside the ZIP.
- **Supported formats**: PNG, JPG, JPEG, GIF, WEBP.
- **Reference syntax**: Standard Markdown image syntax within `content`, `choices[*].content`, or `explanation`.
  ```markdown
  ![Diagram](images/67b52e425871.png)
  ```
- **File naming**: Use content-hash-based names (e.g., `{md5}.{ext}`) to avoid collisions. Avoid spaces and special characters.
- **Size recommendation**: Individual images should not exceed 500KB. Total package media should not exceed 50MB for optimal import performance.

### 7.2 Audio / Video (Reserved)

Protocol 2.0 reserves support for audio and video but does not yet define a standard layout. Future versions may add:

```
audio/
video/
```

---

## 8. Complete Example

```json
{
  "protocol_version": "2.0",
  "subject_name_zh": "航海学",
  "subject_name_en": "navigation",
  "chapters": [
    {
      "title": "第一章 航海基础知识",
      "sections": [
        {
          "title": "第一节 地球形状与地理坐标",
          "questions": [
            {
              "content": "地球椭圆体的扁率约为______。",
              "choices": [
                {"key": "A", "content": "$\\frac{1}{297}$"},
                {"key": "B", "content": "$\\frac{1}{298}$"},
                {"key": "C", "content": "$\\frac{1}{299}$"},
                {"key": "D", "content": "$\\frac{1}{300}$"}
              ],
              "answer": "A",
              "explanation": "地球椭圆体的扁率约为 $\\frac{1}{297.257}$，通常取 $\\frac{1}{297}$。",
              "tags": ["航海学", "地球形状"],
              "difficulty": 2.0
            },
            {
              "content": "下列关于地理纬度的说法，正确的是：",
              "choices": [
                {"key": "A", "content": "某点纬度即该点椭圆子午线法线与赤道面的夹角"},
                {"key": "B", "content": "某点纬度即该点半径与赤道面的夹角"},
                {"key": "C", "content": "某点纬度即该点向径与赤道面的夹角"},
                {"key": "D", "content": "某点纬度即该点椭圆子午线切线与赤道面的夹角"}
              ],
              "answer": "A",
              "explanation": "地理纬度定义为椭圆子午线法线与赤道面的夹角。",
              "tags": ["航海学", "地理坐标"],
              "difficulty": 3.5
            }
          ]
        }
      ]
    }
  ]
}
```

---

## 9. Validation Rules

A conforming Package **MUST** satisfy all of the following:

1. `data.json` exists and is valid JSON.
2. `subject_name_zh` and `subject_name_en` are non-empty strings.
3. `chapters` is a non-empty array.
4. Every chapter has a non-empty `title` and a `sections` array.
5. Every section has a non-empty `title` and a `questions` array.
6. Every question has a non-empty `content`.
7. For `multiple_choice` and `true_false` questions, `choices` must be a non-empty array and `answer` must match one of the `key` values.
8. For `fill_blank`, `cloze`, and `flashcard` questions, `answer` must be non-empty.
9. Passage questions must contain a non-empty `questions` array and are not counted as answerable items.
10. `difficulty`, if present, must be a number between `1.0` and `5.0`.
11. `tags`, if present, must be an array of strings, each not exceeding 50 characters.
12. All image references in `data.json` must point to files that exist in the `images/` directory.

---

## 10. Tooling & Best Practices

### Recommended Workflow

1. **Source data**: Prepare your questions in a structured format (JSON, CSV, or Markdown).
2. **Media collection**: Gather images and place them in an `images/` folder. Use consistent naming.
3. **Build script**: Use a script (Python/Node) to validate against this spec and assemble the ZIP.
4. **Validation checklist**:
   - [ ] JSON is valid and passes a schema validator.
   - [ ] All `answer` values exist in `choices`.
   - [ ] All image references resolve to existing files.
   - [ ] No duplicate `subject_name_en` values across your packages.
   - [ ] Total ZIP size is under 100MB.

### Python Validation Snippet

```python
import json, zipfile, re
from pathlib import Path

def validate_package(zip_path: str) -> list[str]:
    errors = []
    with zipfile.ZipFile(zip_path, 'r') as zf:
        if 'data.json' not in zf.namelist():
            errors.append("Missing data.json")
            return errors
        data = json.loads(zf.read('data.json'))
        
        # Check required fields
        if not data.get('subject_name_zh'): errors.append("Missing subject_name_zh")
        if not data.get('subject_name_en'): errors.append("Missing subject_name_en")
        if not data.get('chapters'): errors.append("Missing chapters")
        
        # Collect image references
        content = zf.read('data.json').decode('utf-8')
        image_refs = re.findall(r'!\[.*?\]\((images/[^)]+)\)', content)
        for ref in image_refs:
            if ref not in zf.namelist():
                errors.append(f"Missing image: {ref}")
    
    return errors
```

---

## 11. Changelog

### v2.0 (2026-04-24)
- Added `protocol_version` field.
- Added optional fields: `question_type`, `tags`, `difficulty`, `note`, `front_template`, `back_template`.
- Added typed support for choice-based questions, answer-reveal questions, and passage containers.
- Added media asset specifications.
- Added validation rules and tooling recommendations.
- Reserved audio/video support for future versions.

### v1.0 (Initial)
- Basic `chapters → sections → questions` hierarchy.
- Support for `content`, `choices`, `answer`, `explanation`.
- Support for nested reading-comprehension questions.
- Support for Markdown/LaTeX in text fields.
- Support for images via Markdown references.
