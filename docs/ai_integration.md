# Gemini AI Integration

The app uses Google's Gemini API to provide intelligent explanations for exam questions.

## Supported Models

The app currently defaults to **Gemini 3.0 Flash**, which offers a balance of speed and reasoning capability. It also supports Claude models.

## Configuration

Users must provide their own API Key in the Settings screen to enable AI features.

- **Provider**: Choose between Gemini and Claude.
- **Model**: Default is `gemini-3.0-flash`.
- **System Prompt**: A customizable prompt that defines the AI's "personality" (e.g., "Professional Maritime Instructor").

## How it Works

When a user taps the "AI Explain" button:
1. The app builds a prompt containing the question stem, options, and the correct answer.
2. This is sent to the configured AI API along with the system prompt.
3. The response is rendered as Markdown in a bottom sheet, allowing the user to ask follow-up questions.
