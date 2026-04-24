# Question Types

Question types define answer semantics. They are not UI components, study modes, or database tables.

A type answers:

- What is shown as the prompt?
- What counts as an answer?
- Can the app grade it deterministically?
- What should be revealed after submission or recall?
- Which modes may use it?

## Type Standard

| Type | Prompt | Answer | Grading | Default Modes | Status |
|------|--------|--------|---------|---------------|--------|
| `multiple_choice` | Stem + choices | One or more choice keys, depending on subtype | Deterministic | Practice, Test, Review | Baseline |
| `true_false` | Statement + two choices | One choice key | Deterministic | Practice, Test, Review | Baseline |
| `fill_blank` | Stem with one or more blanks | Text or accepted answer set | Requires normalization policy | Review first, then Practice/Test | Target |
| `cloze` | Content with hidden spans | Hidden span values | Requires cloze syntax and normalization | Review first, then Practice/Test | Target |
| `flashcard` | Front template/content | Back template/answer | Self-rated | Review | Baseline for Review |
| `passage` | Shared stimulus | None | Not answerable | Preview/context only | Baseline context |

## Universal Requirements

Every answerable item should have:

- Stable identity.
- Human-readable prompt.
- Revealable answer or back side.
- Optional explanation.
- Optional tags and difficulty.
- Clear mode eligibility.

Every auto-gradable item must additionally have:

- Machine-readable answer.
- Validation rules that catch malformed answers.
- Deterministic comparison semantics.
- A way to show why the answer is correct.

## Multiple Choice

Multiple choice is the default imported exam item. It should be used when the learner selects from explicit alternatives.

Required fields:

- `content`
- `choices`
- `answer`

Design rules:

- Choice keys are stable identifiers, not display order.
- Choice content may include Markdown, LaTeX, and images.
- The answer must reference existing choice keys.
- Randomizing choice order should not change correctness.
- The app should eventually support both single-answer and multi-answer variants, but Protocol 2.0 is single-answer by convention.

Avoid:

- Encoding "All of the above" logic outside normal choices.
- Storing the answer as full choice text when a key exists.
- Treating key order as semantic beyond display.

## True/False

True/false is a constrained choice item. It should remain choice-based rather than becoming a separate boolean answer field.

Recommended representation:

```json
{
  "question_type": "true_false",
  "content": "The vessel must maintain a proper lookout at all times.",
  "choices": [
    { "key": "T", "content": "True" },
    { "key": "F", "content": "False" }
  ],
  "answer": "T"
}
```

This preserves keyboard behavior, scoring, option rendering, and source compatibility.

## Fill-in-the-Blank

Fill-in-the-blank is not just a multiple-choice question without choices. It requires an answer normalization policy.

Before it becomes auto-gradable, the design must define:

- Case sensitivity.
- Whitespace and punctuation normalization.
- Accepted answer aliases.
- Numeric tolerance and units.
- Formula or LaTeX equivalence.
- Whether multiple blanks are independently graded.
- Whether partial credit exists.

Until those rules exist, fill-in-the-blank should be imported as an answer-reveal item and used in Review.

Target representation may eventually need:

- `accepted_answers`
- `normalization`
- `blanks`
- `case_sensitive`
- `numeric_tolerance`

Do not fake deterministic grading with raw string equality for serious exams.

## Cloze

Cloze is structured omission from a larger text. It is best for recall, terminology, formula components, and procedural steps.

The future design should define cloze spans explicitly rather than relying on Markdown conventions.

Preferred future direction:

```json
{
  "question_type": "cloze",
  "content": "A vessel is underway when it is not at anchor, made fast to the shore, or aground.",
  "cloze_spans": [
    { "id": "c1", "text": "underway" },
    { "id": "c2", "text": "aground" }
  ]
}
```

Design rules:

- Cloze markers must not conflict with Markdown or LaTeX syntax.
- Each cloze span should have stable identity.
- A single source note may generate multiple review cards.
- Hints and synonyms should be explicit metadata, not hidden in explanation text.

## Flashcard

Flashcards are self-rated recall items. They are not exam questions by default.

Fields:

- `content` or `front_template` for the front side.
- `answer` or `back_template` for the back side.
- `explanation` for supporting detail.

Design rules:

- Front side should ask for one recall task.
- Back side should be concise enough for self-rating.
- Explanation should clarify, not become the answer itself.
- Flashcards belong in Review unless a future mode explicitly supports self-graded practice.

Avoid:

- Cards with multiple unrelated facts.
- Cards that require subjective essay evaluation.
- Cards whose answer is only implied by a long explanation.

## Passage

Passage is a context container. It can represent:

- Reading passage.
- Chart or diagram stimulus.
- Case/scenario.
- Shared source excerpt.
- Multi-question data table.

A passage:

- Has content.
- Has child answerable items.
- Has no direct answer.
- Is not scheduled.
- Is not scored.
- Is not counted as a question.

If a passage has no child questions, it is content for Preview only and should not enter learning workflows.

## Type Evolution Rules

New question types must not be added just because the UI needs a different visual treatment. Add a type only when answer semantics differ.

A proposed new type must specify:

- Prompt structure.
- Answer structure.
- Grading model.
- Reveal model.
- Mode eligibility.
- Validation rules.
- Migration behavior.
- How it appears in analytics.

## Current Implementation Boundary

The current app fully supports choice-based items in Practice, Test, and Review. It can import answer-reveal items and show them in Review. It does not yet implement typed input grading, cloze span generation, multi-answer grading, partial credit, or exam blueprints.
