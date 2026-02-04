# Data Packages

The application supports a "pluginable" architecture, allowing users to import custom question banks via zip packages.

## Built-in Sample Package

On first launch, if no question banks exist, the app automatically imports a built-in sample package from `assets/packages/sample-quiz.zip`. This provides 7 example questions for immediate testing.

## For Users: How to Import

1.  **Prepare your package:** Ensure you have a valid `.zip` or `.quizpkg` file containing the question data (and optional images).
2.  **Open the App:** Navigate to the Home Screen.
3.  **Tap the Import Button:** Click the "Import Package" icon (upload icon) in the top-right corner.
4.  **Select File:** Choose your package file from the system file picker.
5.  **Wait for Import:** A progress dialog shows the import status:
    - Selecting file...
    - Preparing...
    - Extracting...
    - Validating package structure...
    - Importing questions...
    - Complete!
6.  **Start Practicing:** The new question bank will appear in the list. Tap it to select a mode and start.

### Import Errors

If import fails, an error dialog will show the reason:
- **Invalid file type**: Only `.zip` or `.quizpkg` files are supported
- **No data.json found**: The package must contain a `data.json` file
- **Invalid JSON format**: The data.json file has syntax errors
- **Failed to extract**: The zip file may be corrupted

## For Developers: Creating Packages

A valid data package is a standard ZIP archive containing at least a `data.json` file. It can optionally contain an `images/` directory for local assets.

### File Structure

```text
my_question_bank.zip
├── data.json          (Required) Main data file
└── images/            (Optional) Folder for image assets
    ├── diagram1.png
    └── chart_a.jpg
```

### data.json Format

The `data.json` file must follow this structure. It defines the hierarchy of Books -> Chapters -> Sections -> Questions.

```json
{
  "subject_name_zh": "My Custom Subject",
  "subject_name_en": "my-custom-subject",
  "chapters": [
    {
      "title": "Chapter 1: Basics",
      "sections": [
        {
          "title": "Section 1.1: Introduction",
          "questions": [
            {
              "content": "<p>What is the capital of France?</p>",
              "choices": [
                {"key": "A", "html": "London"},
                {"key": "B", "html": "Paris"},
                {"key": "C", "html": "Berlin"}
              ],
              "answer": "B",
              "explanation": "<p>Paris is the capital of France.</p>"
            },
            {
              "content": "<p>Identify this symbol:</p><img src=\"images/symbol_a.png\">",
              "choices": [
                {"key": "A", "html": "Stop"},
                {"key": "B", "html": "Go"}
              ],
              "answer": "A",
              "explanation": "<p>This is a stop sign.</p>"
            }
          ]
        }
      ]
    }
  ]
}
```

### Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `subject_name_zh` | Yes | Display name (Chinese) |
| `subject_name_en` | Yes | Display name (English) / identifier |
| `chapters` | Yes | Array of chapter objects |
| `chapters[].title` | Yes | Chapter title |
| `chapters[].sections` | Yes | Array of section objects |
| `sections[].title` | Yes | Section title |
| `sections[].questions` | Yes | Array of question objects |
| `questions[].content` | Yes | Question text (HTML supported) |
| `questions[].choices` | Yes | Array of choice objects |
| `questions[].answer` | Yes | Correct answer key (e.g., "A", "B") |
| `questions[].explanation` | No | Explanation text (HTML supported) |
| `choices[].key` | Yes | Choice identifier (e.g., "A", "B", "C", "D") |
| `choices[].html` | Yes | Choice text (HTML supported) |

### Image Handling

-   **Location:** Place all images in the `images/` folder within the zip.
-   **Reference:** In your JSON `content` or `explanation` fields, refer to images using relative paths: `src="images/filename.jpg"`.
-   **Rendering:** The app automatically detects these paths and resolves them to the locally unzipped files at runtime.

### Best Practices

-   **Unique Filenames:** Use descriptive package filenames (e.g., `navigation_2024.zip`). The app appends a timestamp to avoid conflicts.
-   **Image Size:** Keep images optimized (recommend < 500KB each) to reduce package size and loading time.
-   **HTML Support:** Question content supports basic HTML tags: `<p>`, `<b>`, `<i>`, `<img>`, `<br>`, `<ul>`, `<li>`, etc.
-   **Testing:** Test your package with the sample structure before distributing.

### Creating a Package (Command Line)

```bash
# Create package directory
mkdir my-quiz
cd my-quiz

# Create data.json with your questions
cat > data.json << 'EOF'
{
  "subject_name_zh": "My Quiz",
  "subject_name_en": "my-quiz",
  "chapters": [...]
}
EOF

# Add images if needed
mkdir images
cp /path/to/images/* images/

# Create zip package
zip -r ../my-quiz.zip data.json images/
```
