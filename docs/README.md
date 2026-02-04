# Quiz App

Welcome to the documentation for **Quiz App**, a general extensible quiz framework application.

## Directory Structure

- `docs/architecture.md`: Technical overview of the application components.
- `docs/data_packages.md`: Guide on how to create and import custom quiz data packages.
- `docs/ai_integration.md`: Details about the Gemini AI integration for question explanation.

## Getting Started

### Development Requirements
- Flutter SDK (^3.10.4)
- Android SDK (API 21+)
- Gemini API Key (optional, for AI features)

### Running the App
1. Connect an Android device with USB debugging enabled.
2. Run `flutter pub get`.
3. Run `flutter run`.

### Built-in Sample Package
On first launch, if no question banks exist, the app automatically imports a built-in sample quiz package (`assets/packages/sample-quiz.zip`) with 7 example questions for testing.

## Features

- **Multiple Quiz Modes**: Practice, Review, Memorize, and Test modes
- **Progress Tracking**: Automatically saves your progress per question bank
- **Import Packages**: Import custom question banks via ZIP files
- **AI Explanations**: Get AI-powered explanations with Markdown and LaTeX support
- **Sound & Visual Feedback**: Configurable sound effects, vibration, and confetti
- **Localization**: Supports English and Chinese
- **Dark Mode**: System, light, or dark theme options
