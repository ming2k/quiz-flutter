# Study Modes

Study modes are workflows. They define intent, state changes, feedback timing, scoring, and scheduling. They must not redefine what a question is.

Mnema should support four first-class workflows:

- Preview: inspect content without learning-state side effects.
- Practice: answer auto-gradable items with immediate feedback.
- Test: answer a frozen auto-gradable set under exam-like constraints.
- Review: recall answerable items through SRS and self-rating.

## Mode Eligibility

| Item | Preview | Practice | Test | Review |
|------|---------|----------|------|--------|
| Multiple choice | Yes | Yes | Yes | Yes |
| True/false | Yes | Yes | Yes | Yes |
| Fill-in-the-blank | Yes | Only after grading policy exists | Only after grading policy exists | Yes |
| Cloze | Yes | Only after cloze syntax and grading exist | Only after cloze syntax and grading exist | Yes |
| Flashcard | Yes | No by default | No by default | Yes |
| Passage/context parent | Yes | No | No | No |

Eligibility is type-level by default, but individual items may be excluded by package validation if required fields are missing.

## Preview

Preview is for reading, inspection, author QA, and content navigation. It is the only mode that may show non-answerable context containers as first-class content.

Preview should show:

- Rendered Markdown, LaTeX, images, and media references.
- Question type, tags, difficulty, source position, and collection membership.
- Parent passage and child list when inspecting a shared-stimulus group.
- Validation warnings when the package is incomplete or ambiguous.

Preview must not:

- Persist answer attempts.
- Change correctness statistics.
- Create or update SRS records.
- Write test history.

The product reason is simple: looking at material is not the same as attempting it.

## Practice

Practice is a fast feedback loop for building correctness. It should prioritize answer submission, immediate correction, explanation, navigation, and recovery from mistakes.

Practice should:

- Include only deterministic, auto-gradable items.
- Save the learner's selected answer and correctness.
- Show the correct answer and explanation immediately after submission.
- Support section/collection filters, bookmarks, wrong-question review, and progress overview.
- Keep parent passage content visible when answering child questions.

Practice should not:

- Include passage parents as separate items.
- Include answer-reveal cards that cannot be graded.
- Mutate SRS scheduling unless a future design explicitly couples Practice and Review.

For fill-in-the-blank or cloze to enter Practice, the app must first define normalization, accepted alternatives, partial-credit policy, and display of grading disputes.

## Test

Test is an assessment snapshot. It should produce a score that can be trusted, replayed, and compared over time.

Test should:

- Freeze the question set, order, start time, and scoring rules at session start.
- Include only deterministic, auto-gradable items.
- Record answer, correctness, duration, unanswered count, and source/collection metadata.
- Preserve parent passage context for child questions.
- Avoid showing explanations until the test is submitted.

Test should not:

- Include self-rated flashcards by default.
- Include ungraded fill-in-the-blank or cloze items.
- Update SRS due dates.
- Change item eligibility mid-session if settings or content changes.

The target design should eventually support exam blueprints: fixed counts by collection, topic, difficulty, or source section. Random draw alone is not a sufficient long-term test model.

## Review

Review is memory scheduling. It optimizes recall, not assessment purity.

Review should:

- Include any answerable item with a revealable answer side.
- Show the prompt first, then reveal the answer/back side.
- Ask the learner to rate recall with a small, stable set of ratings.
- Update SRS state only after a rating is submitted.
- Use parent passage content only when needed to answer the child item.

Review may include:

- Multiple choice, shown as a card before revealing options and answer.
- Fill-in-the-blank, shown as a prompt before revealing the expected answer.
- Cloze cards, shown with hidden spans before revealing filled content.
- Flashcards, shown as front/back cards.

Review must not schedule passage parents. It may show a passage as supporting context for a child card, but the child remains the scheduled item.

## Cross-Mode State Rules

| State | Preview | Practice | Test | Review |
|-------|---------|----------|------|--------|
| Answer history | No write | Write | Write to test session | No direct write unless explicitly designed |
| Correctness stats | No | Yes | Yes | No, SRS rating is separate |
| SRS state | No | No by default | No | Yes |
| Bookmark/mark | May edit | May edit | May edit | May edit |
| AI chat | May read/write on answerable item | May read/write | May read/write after reveal/submission policy | May read/write after reveal |
| Collection position | Read only | Read only | Snapshotted | Read only |

## Design Smells

- A mode contains a special-case version of the question schema.
- A passage parent appears in "total questions" counts.
- A test includes items the app cannot grade deterministically.
- Review ratings are treated as correct/wrong answers.
- Changing a collection order breaks old test history.
- Preview creates progress just because the user viewed an item.

## Acceptance Checklist

Before adding or changing a mode, confirm:

- The mode has a clear learning intent.
- The item eligibility rules are explicit.
- Side effects are listed and testable.
- Passage and nested-question behavior is defined.
- The mode can explain why an item was included or excluded.
- Existing progress and test history remain interpretable.
