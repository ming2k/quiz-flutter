# Changelog

## [1.2.0] - 2026-02-25

### Added
- **Internationalization (i18n)**: Full localization support using `flutter gen-l10n` with ARB files for English and Chinese.

### Changed
- **Overview Sheet Filters**: Replaced scrollable text chips with icon-only buttons that divide the screen width equally and support single selection.
- **UI & Bug Fixes**: Addressed multiple layout and logic issues across quiz, home, settings, and test result screens; improved toast animations and AI chat panel behavior.

## [1.1.0] - 2026-02-07

### Added
- **Customizable Mock Tests**: Added a scrollable selector (CupertinoPicker) to choose the number of questions before starting a test.
- **Action Bar**: Introduced a new Action Bar in the Quiz Screen for quick access to Mark, AI Explain, and Reset functions.
- **Standardized UI Components**: Created a reusable `BottomSheetHandle` to ensure consistent design across all modal sheets.

### Changed
- **Refactored Quiz UI**: Moved question order display to the AppBar and optimized the layout for better content focus.
- **Improved Navigation**: Enhanced horizontal swiping between questions with smooth synchronization between the PageView and Action Bar.
- **AI Chat Enhancements**: Redesigned Markdown styling for blockquotes and code blocks to improve contrast and readability in chat bubbles.
- **UI Polishing**: Standardized bottom sheet handles and optimized vertical spacing in the AI chat panel.

## [1.0.0+1] - 2026-02-07

### Added
- Initial release of the quiz framework.
- Support for multiple quiz books and sections.
- AI integration for hints and explanations.
- Local database for progress tracking.
- Markdown and LaTeX support for questions.
- Haptic feedback and sound effects.
