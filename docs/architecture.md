# Technical Architecture

The application is built using Flutter and follows a Provider-based state management pattern.

## Project Structure

```
lib/
├── main.dart              # App entry point
├── l10n/                  # Localization
│   └── app_localizations.dart
├── models/                # Data models
│   ├── book.dart
│   ├── question.dart
│   ├── section.dart
│   ├── user_progress.dart
│   ├── chat_message.dart
│   ├── test_history.dart
│   └── models.dart        # Barrel export
├── providers/             # State management
│   ├── quiz_provider.dart
│   ├── settings_provider.dart
│   └── providers.dart     # Barrel export
├── screens/               # UI screens
│   ├── home_screen.dart
│   ├── quiz_screen.dart
│   ├── settings_screen.dart
│   ├── overview_screen.dart
│   ├── test_result_screen.dart
│   └── screens.dart       # Barrel export
├── services/              # Business logic
│   ├── database_service.dart
│   ├── storage_service.dart
│   ├── package_service.dart
│   ├── ai_service.dart
│   ├── sound_service.dart
│   └── services.dart      # Barrel export
├── theme/
│   └── app_theme.dart
└── widgets/               # Reusable widgets
    ├── question_card.dart
    ├── section_selector.dart
    ├── ai_chat_panel.dart
    ├── stats_display.dart
    ├── test_history_list.dart
    └── widgets.dart       # Barrel export
```

## Core Components

### 1. Presentation Layer (UI)
- **Screens**: Located in `lib/screens/`. Main entry point is `HomeScreen`.
- **Widgets**: Reusable UI components in `lib/widgets/`. The `QuestionCard` is the primary widget for rendering exam questions.

### 2. State Management (Providers)
- **QuizProvider**: Manages the current quiz state, including book selection, question filtering, navigation, and progress tracking.
- **SettingsProvider**: Manages app-wide settings like theme mode, locale, and AI configuration.

### 3. Services (Data & Logic)
- **DatabaseService**: Interfaces with the local SQLite database (`sqflite`). Creates schema on first run and handles data import.
- **StorageService**: Manages persistent simple settings and user progress using `shared_preferences`.
- **PackageService**: Handles importing zip-based data packages, including extraction, validation, and built-in package loading from assets.
- **AiService**: Manages communication with Gemini/Claude APIs for AI-powered question explanations.
- **SoundService**: Pre-loads and plays sound effects (correct/wrong) with minimal latency.

## Data Flow

1. On first launch, `QuizProvider` checks for existing books. If none, it imports the built-in sample package via `PackageService`.
2. User selects a **Book** from the `HomeScreen`.
3. `QuizProvider` loads the book data from `DatabaseService`.
4. If the book is an imported package, `PackageService` identifies the local image path.
5. User answers questions; progress is saved asynchronously via `StorageService`.
6. Sound feedback is provided via `SoundService` (pre-loaded for instant playback).
7. AI explanations are requested via `AiService` and displayed in a chat panel.

## Database Schema

The app uses SQLite with the following tables:

```sql
-- Question banks
books (id, filename, subject_name_zh, subject_name_en, total_questions, total_chapters, total_sections, sort_order)

-- Chapters within a book
chapters (id, book_id, title, question_count)

-- Sections within a chapter
sections (id, book_id, chapter_id, title, question_count)

-- Individual questions
questions (id, book_id, section_id, parent_id, content, choices, answer, explanation)
```

## Assets

```
assets/
├── packages/           # Built-in quiz packages
│   └── sample-quiz.zip
├── sounds/             # Sound effects
│   ├── correct.wav
│   └── wrong.wav
└── images/             # App icon assets
    └── app_icon.png
```
