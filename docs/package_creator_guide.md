# Mnema Package Creator Guide

> **Target Audience**: Content creators, educators, and community members who want to build quiz packages for the Mnema app.
>
> **Prerequisites**: Basic familiarity with JSON and file management.

---

## What is a Mnema Package?

A **Package** is a self-contained ZIP archive that contains exam questions, metadata, and optional media assets. Anyone can create a package, share it with others, and import it into the Mnema app.

Packages support:
- Multiple question types (multiple choice, true/false, fill-in-the-blank, cloze, flashcard, and reading comprehension passages)
- Markdown and LaTeX formatting in text
- Images embedded via Markdown syntax
- Difficulty ratings, tags, and explanations

---

## Quick Start

### 1. Create Your Package Directory

Create a folder with this structure:

```
my-quiz/
├── data.json          (required)
└── images/            (optional)
    ├── diagram-01.png
    └── photo-02.jpg
```

### 2. Write `data.json`

At minimum, `data.json` needs three top-level fields:

```json
{
  "subject_name_zh": "我的测验",
  "subject_name_en": "my-quiz",
  "chapters": [
    {
      "title": "第一章",
      "sections": [
        {
          "title": "第一节",
          "questions": [
            {
              "content": "世界上最高的山峰是？",
              "choices": [
                {"key": "A", "content": "乞力马扎罗山"},
                {"key": "B", "content": "珠穆朗玛峰"},
                {"key": "C", "content": "富士山"}
              ],
              "answer": "B",
              "explanation": "珠穆朗玛峰海拔约 8,848.86 米。"
            }
          ]
        }
      ]
    }
  ]
}
```

### 3. Validate

Run the validator on your `data.json` before packaging:

```bash
python tools/validate_package.py my-quiz/data.json
```

### 4. Build the Package

```bash
python tools/build_package.py my-quiz ./output
```

This creates `output/my-quiz.zip`, ready to share or import into the Mnema app.

---

## Question Types

### Multiple Choice (Default)

The most common type. Requires `content`, `choices`, and `answer`.

```json
{
  "content": "光速约为多少？",
  "choices": [
    {"key": "A", "content": "30 万公里/秒"},
    {"key": "B", "content": "10 万公里/秒"},
    {"key": "C", "content": "100 万公里/秒"}
  ],
  "answer": "A",
  "explanation": "真空中光速约为 299,792,458 m/s。",
  "tags": ["物理"],
  "difficulty": 2.0
}
```

**Choice fields**: Each choice is an object with `key` and one of `content`, `html`, or `text`. All three are accepted; `content` is preferred.

### True / False

A special case of multiple choice with exactly two options.

```json
{
  "content": "地球是太阳系中唯一的行星。",
  "question_type": "true_false",
  "choices": [
    {"key": "A", "content": "正确"},
    {"key": "B", "content": "错误"}
  ],
  "answer": "B",
  "explanation": "太阳系有八大行星。"
}
```

### Fill in the Blank

```json
{
  "content": "水的化学式是___。",
  "question_type": "fill_blank",
  "answer": "H₂O",
  "explanation": "水由氢和氧组成。",
  "tags": ["化学"]
}
```

### Cloze Deletion

Use `{{c1::...}}` syntax in content to mark the hidden portion.

```json
{
  "content": "{{c1::线粒体}}是细胞的能量工厂。",
  "question_type": "cloze",
  "answer": "线粒体",
  "explanation": "线粒体通过有氧呼吸产生 ATP。"
}
```

### Flashcard

Shown as answer-reveal cards in Review mode.

```json
{
  "content": "光合作用的定义是什么？",
  "question_type": "flashcard",
  "answer": "绿色植物利用光能将 CO₂ 和 H₂O 转化为有机物并释放 O₂ 的过程。",
  "explanation": "这是地球上几乎所有生命能量的最初来源。",
  "front_template": "什么是光合作用？",
  "back_template": "植物利用光能合成有机物的过程。"
}
```

- `front_template` (optional): Overrides `content` for the front side.
- `back_template` (optional): Overrides `answer` + `explanation` for the back side.

### Reading Comprehension (Passage)

A parent question with nested sub-questions sharing the same context.

```json
{
  "content": "恐龙生活在中生代，支配全球陆地生态系统超过 1.6 亿年。",
  "question_type": "passage",
  "questions": [
    {
      "content": "恐龙最早出现在哪个地质年代？",
      "choices": [
        {"key": "A", "content": "侏罗纪"},
        {"key": "B", "content": "三叠纪"}
      ],
      "answer": "B",
      "explanation": "恐龙最早出现在约 2.3 亿年前的三叠纪。"
    }
  ]
}
```

- The parent is **not** counted as an answerable question.
- Sub-questions follow the same schema as standalone questions.

---

## Formatting

### Markdown

Supported in `content`, `choices[*].content`, and `explanation`:

- `**bold**` → **bold**
- `*italic*` → *italic*
- `\`inline code\`` → `inline code`
- `[link](url)` → link

### LaTeX Math

Use standard MathJax syntax:

- Inline: `$E = mc^2$`
- Display: `$$\sum_{i=1}^{n} x_i$$`

### Images

Place images in the `images/` folder and reference them with Markdown:

```json
{
  "content": "如下图所示，该结构是：\n\n![Cell Diagram](images/cell-mitochondria.png)"
}
```

**Image guidelines**:
- Formats: PNG, JPG, JPEG, GIF, WEBP
- Max 500KB per image
- Total package media under 50MB
- Use hash-based filenames (e.g., `a3f7c2d1.png`) to avoid collisions

---

## Validation Checklist

Before sharing your package, verify:

- [ ] `data.json` is valid UTF-8 JSON
- [ ] `subject_name_zh` and `subject_name_en` are non-empty strings
- [ ] `chapters` is a non-empty array
- [ ] Every chapter has a `title` and `sections`
- [ ] Every section has a `title` and `questions`
- [ ] Every question has non-empty `content`
- [ ] Multiple choice / true-false questions have `choices` and a matching `answer`
- [ ] Fill-blank / cloze / flashcard questions have non-empty `answer`
- [ ] All image references in `data.json` resolve to files in `images/`
- [ ] `difficulty` is between 1.0 and 5.0 (if used)
- [ ] `tags` is an array of strings, each under 50 characters

Run the automated validator to catch issues:

```bash
# Validate JSON before packaging
python tools/validate_package.py my-quiz/data.json

# Validate the final ZIP
python tools/validate_package.py output/my-quiz.zip

# Strict mode (enforces naming conventions and best practices)
python tools/validate_package.py --strict output/my-quiz.zip
```

---

## Distribution

Once built, your `.zip` file can be:

1. **Shared directly** - Send the file to others; they can import it via the app's "Import Package" button.
2. **Hosted online** - Upload to a file server or cloud storage and share the download link.
3. **Bundled as a built-in package** - For app developers: place the ZIP in `assets/packages/` and load it with `PackageService.importBuiltInPackage()`.

**File extensions**: `.zip` (standard), `.quizpkg`, or `.mnemapkg` (all treated identically by the app).

---

## Example Package

See `examples/minimal-package/` in this repository for a complete, working example that includes every supported question type.

---

## Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| "Missing data.json" | ZIP was created with a root folder | Flatten the ZIP so `data.json` is at the root, or use `build_package.py` |
| "Answer does not match any choice key" | `answer` value case mismatch | Ensure `answer` exactly matches one `key` (case-insensitive check) |
| "Missing image file" | Image referenced but not included | Place the image in `images/` and rebuild |
| "Invalid JSON" | Trailing comma or unquoted key | Use a JSON linter; run `validate_package.py` |
| Import succeeds but questions don't appear | All questions are passage parents with no sub-questions | Ensure sub-questions are inside `questions` array |

---

## Need Help?

- Read the full technical spec: [`docs/package_protocol.md`](package_protocol.md)
- Check the JSON Schema: [`docs/package_schema.json`](package_schema.json)
- Inspect the example fixture: [`test/fixtures/minimal_package.json`](../test/fixtures/minimal_package.json)
