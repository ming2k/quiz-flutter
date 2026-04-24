# Question Structure

Question structure defines how prompts, shared context, answerable leaves, and identity relate to each other.

The central rule is:

Answerable items are leaves. Context containers are parents.

## Conceptual Model

```text
QuestionBank
  ContextContainer?        optional
    AnswerableItem         one or more
```

An answerable item may be standalone or may depend on a context container.

Context containers may include text, images, charts, tables, formulas, scenarios, or source excerpts. They are part of the presentation, not the learner's answer history.

## Standalone Item

A standalone item contains all information needed to answer it.

```json
{
  "question_type": "multiple_choice",
  "content": "Which signal indicates danger?",
  "choices": [
    { "key": "A", "content": "Signal A" },
    { "key": "B", "content": "Signal B" }
  ],
  "answer": "A"
}
```

Use standalone items when:

- No shared stimulus is needed.
- The item can be shuffled independently.
- The item can be explained independently.
- The item can be scheduled independently.

## Shared-Stimulus Group

A shared-stimulus group contains one context parent and one or more answerable children.

```json
{
  "question_type": "passage",
  "content": "Read the following chart and answer the questions.",
  "questions": [
    {
      "question_type": "multiple_choice",
      "content": "What is the safe depth?",
      "choices": [
        { "key": "A", "content": "10 m" },
        { "key": "B", "content": "20 m" }
      ],
      "answer": "B"
    }
  ]
}
```

Use shared-stimulus groups when:

- Several questions rely on the same passage, table, diagram, or case.
- Repeating the context inside every child would be noisy or error-prone.
- The child questions remain meaningful learning units.

Do not use shared-stimulus groups merely to create visual grouping. Collections handle organization; passages handle required context.

## Counting Rules

The app should count learning work, not rows.

| Structure | Counted as Question? | Scheduled? | Scored? |
|-----------|----------------------|------------|---------|
| Standalone answerable item | Yes | Yes, if eligible | Yes, if mode grades |
| Child answerable item | Yes | Yes, if eligible | Yes, if mode grades |
| Passage/context parent | No | No | No |
| Empty passage | No | No | No |

These rules apply to package totals, section totals, SRS totals, test draws, analytics, and progress indicators.

## Identity Rules

Identity must be stable at the answerable-item level.

Progress attaches to:

- Standalone question ID.
- Child question ID.

Progress does not attach to:

- Passage parent ID.
- Collection position.
- Current sort order.
- Rendered page number.

If a passage changes but child items remain semantically the same, child progress should survive. If a child item's answer semantics change, migration should treat it as a new answerable item or explicitly invalidate old progress.

## Parent Context Rules

When rendering a child item, the app should show enough parent context to answer the item, but not make the parent look like a separate task.

Recommended UI behavior:

- Show parent content above the child stem.
- Visually distinguish context from the child question.
- Keep parent content available when revealing answers and AI explanations.
- Avoid counting parent content in "question X of Y".

For long passages, future UI should support collapse, sticky headings, or split reading/answer panes. The data model should not encode those UI decisions.

## Nesting Depth

The ideal product model supports one context level:

```text
passage -> answerable child
```

Protocol recursion may exist for compatibility, but deeper nesting should be treated as import complexity, not product design.

If source material has deeper nesting:

- Flatten structural groups into collection hierarchy when they are organizational.
- Flatten explanatory parent nodes into the passage content when they are contextual.
- Preserve only the answerable leaves as progress-bearing items.

Deeper nesting should be allowed only when there is a clear user-facing reason and a tested rendering model.

## Multi-Part Questions

Some exam sources present a stem followed by several sub-questions. Treat these as shared-stimulus groups when each sub-question has its own answer and score.

Do not merge sub-questions into one answerable item unless:

- The source grades them as one unit.
- The learner must answer all parts together.
- The app has a compound-answer interaction for that type.

## AI and Explanation Context

AI explanations should receive:

- Child question content.
- Parent context when present.
- Choices and selected answer when applicable.
- Correct answer.
- Explanation and note.
- Source/collection metadata when useful.

AI history should attach to the answerable child. The passage can be included as context, but it should not own the conversation.

## Validation Rules

A package importer should warn or fail when:

- A passage has an answer but also child questions.
- A passage has no child questions and is not marked as preview-only content.
- A child question lacks answer semantics.
- A child question depends on missing media.
- A parent contains several unrelated contexts that should be separate groups.
- A child duplicates the entire parent content unnecessarily.

## Current Implementation Boundary

The current SQLite model stores passages and questions in one table:

- parent passage: `questions` row with `question_type = passage`
- child item: `questions` row with `parent_id`
- displayed context: resolved from the parent row

This is acceptable for Protocol 2.0, but the target domain model should continue treating context containers and answerable items as separate concepts even if they share storage.
