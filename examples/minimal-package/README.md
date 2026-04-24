# Minimal Example Package

This is a complete, working example of a Mnema quiz package that demonstrates every supported question type.

## Structure

```
minimal-package/
├── data.json          # Package data (required)
└── images/            # Media assets (optional, empty in this example)
```

## Question Types Covered

| Section | Type | Count |
|---------|------|-------|
| 1.1 | Multiple Choice | 2 |
| 1.2 | True / False | 1 |
| 1.3 | Fill in the Blank | 1 |
| 1.4 | Flashcard | 1 |
| 2.1 | Reading Comprehension (Passage + 2 sub-questions) | 1 parent + 2 children |

## Build

```bash
python ../../tools/build_package.py . ../../output
```

## Validate

```bash
python ../../tools/validate_package.py data.json
```

## Import

The resulting `.zip` can be imported directly into the Mnema app via **Home → Import Package**.
