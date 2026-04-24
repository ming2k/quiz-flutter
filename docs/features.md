# Feature Overview

> This document is for **users** and **developers** to quickly understand the app's core capabilities and direction.

---

## 1. Core Study Modes

### Practice Mode
- Instant feedback: shows correctness, analysis, and the right answer immediately after selection.
- Auto-advance: optionally jumps to the next question after a correct answer.
- Navigation: chapter selector, question overview grid, previous/next buttons.
- Keyboard/gamepad support: number keys select options, arrow keys navigate, Enter confirms.

### Test Mode
- Simulated exam: randomly draws a configurable number of questions from the selected bank.
- Timer: tracks total time for the entire test session.
- Score report: shows accuracy, breakdown, and time spent.
- History: persists every test result for later review.

### Review / SRS Mode
- Based on the SM-2 spaced-repetition algorithm.
- Four rating levels: Again / Hard / Good / Easy, each affecting the next review interval.
- Card lifecycle: New → Learning → Review → Relearning.
- Daily due count: shown on the home screen as a per-book badge.

---

## 2. Content Rendering

### Rich Text Support
- **Markdown**: questions and explanations support bold, lists, code blocks, etc.
- **LaTeX**: rendered via `flutter_math_fork` (`$...$` inline, `$$...$$` block).
- **Images**: quiz packages can include images referenced with relative paths.
- **Text-selection menu**: customizable menu items (e.g. dictionary lookup) with draggable ordering.

### Quiz Package System (Protocol 2.0)
- Import `.zip` or `.quizpkg` files.
- Package structure: `data.json` + optional `images/` directory.
- Reading comprehension: parent question (passage) + nested sub-questions.
- Question types: choice-based questions for Practice/Test, answer-reveal items for Review, and passage containers for shared context.
- Built-in sample package auto-imported on first launch.

---

## 3. AI Assistance

### AI Explain
- Multi-provider support: Gemini (Google), Kimi (Moonshot AI).
- Streaming responses: AI-generated explanations appear in real time.
- Multi-session: multiple independent chat threads per question, with history switching and deletion.
- Quick prompts: preset templates (e.g. "Detailed analysis", "Why are the other options wrong?").

### AI Configuration
- Customizable API Key, Base URL, and Model ID.
- Custom system prompt support.
- All settings are stored locally; no data is uploaded to third-party servers without explicit user action.

---

## 4. Feedback & Motivation

### Multi-modal Feedback (Modular Design)
- **Sound**: correct / wrong / streak-escalation audio (supports multiple themes; currently ships with 1 default theme).
- **Haptics**: dull thud for errors, crisp tick for correct answers, double-tap for streak milestones.
- **Continuous feedback toggle**: when disabled, the default sound and haptic are used for every answer.
- **Confetti**: green border glow on correct answers.

### Streak System
- Consecutive correct answers trigger escalating streak sounds (1 → 2 → 3 → 4 → 5 → Ace).
- A wrong answer resets the streak counter immediately.

---

## 5. Personalization Settings

| Setting | Description |
|---------|-------------|
| Theme | System / Light / Dark |
| Language | Chinese (Simplified) / English |
| Auto-advance | Jump to next question after correct answer |
| Show analysis | Display explanation after answering |
| Show notes | Show question notes |
| Sound effects | Answer sound toggle |
| Haptic feedback | Device vibration toggle |
| Continuous feedback | Streak escalation toggle |
| Confetti effect | Green glow toggle |
| Test question count | 5 – 200, step 5 |

---

## 6. Data & Persistence

- **SQLite**: questions, answer history, bookmarks, SRS state, AI chat history.
- **SharedPreferences**: user progress (current index, mode, partition) and settings.
- **Import / Export**: quiz package ZIP import; test history export is planned for the future.

---

## 7. Roadmap

### Near-term
- [ ] Multiple sound themes (requires sourcing / creating additional audio assets)
- [ ] Per-entry test history deletion and sharing
- [ ] Section-level test result breakdown

### Mid-term
- [ ] Per-question user notes
- [ ] Dedicated favorites / wrong-question notebook
- [ ] Local data backup and restore

### Long-term
- [ ] Cloud sync (optional self-hosted backend)
- [ ] Community quiz package marketplace
- [ ] Rich analytics (study calendar, skill radar charts)
