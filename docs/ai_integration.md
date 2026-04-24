# AI Integration

The app supports multiple AI providers to provide intelligent explanations for exam questions.

## Supported Providers

### Gemini (Google)
- **Default Model**: `gemini-3.1-flash-lite-preview`
- **Base URL**: `https://generativelanguage.googleapis.com` (or custom)
- **Authentication**: API Key via `x-goog-api-key` header
- **Features**: Streaming responses, context caching, thinking config

### Kimi (Moonshot AI)
- **Default Model**: `kimi-k2.6`
- **Base URL**: `https://api.moonshot.cn` (or custom)
- **Authentication**: API Key via `Authorization: Bearer <key>` header
- **Features**: Streaming responses, OpenAI-compatible API format
- **Other Models**: `kimi-k2.5`, `kimi-k2-turbo-preview`

## Configuration

Users must provide their own API Key in the Settings screen to enable AI features.

- **Provider**: Choose between Gemini and Kimi.
- **Model**: Defaults to the selected provider's recommended model.
- **Base URL**: Optional. Leave empty to use the provider's official endpoint.
- **System Prompt**: A customizable prompt that defines the AI's "personality" (e.g., "Professional Maritime Instructor").

## How it Works

When a user taps the "AI Explain" button:
1. The app builds a prompt containing the question stem, options, and the correct answer.
2. This is sent to the configured AI API along with the system prompt, which instructs the AI to use Markdown and LaTeX for clarity.
3. The response is rendered as native Markdown and LaTeX in a bottom sheet, allowing the user to ask follow-up questions.

## API Compatibility

- **Gemini**: Uses the native Gemini API format (`contents`, `systemInstruction`, `generationConfig`).
- **Kimi**: Uses the OpenAI-compatible Chat Completions API format (`messages`, `stream`, `temperature`, `max_tokens`).
