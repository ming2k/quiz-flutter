# Collection Model

Collections organize learning. They should describe how a learner or author navigates, filters, practices, and tests a question bank without duplicating question records.

The current package hierarchy is useful, but it is not enough as the long-term model.

## Current Compatibility Model

Protocol 2.0 imports:

```text
Book / Package
  Chapter
    Section
      Question
```

This should remain supported because many source materials are naturally book-shaped and existing packages depend on it.

However, this shape is a compatibility layer, not the ideal domain model.

## Target Domain Model

```text
QuestionBank
  Questions
  Media
  Collections
    Collection
      Collection
      QuestionRef
  Tags
  Blueprints
```

Where:

- `QuestionBank` owns imported content, media, source metadata, and update identity.
- `Question` is the canonical answerable item or context container.
- `Collection` is an ordered grouping node.
- `QuestionRef` points to a question without copying it.
- `Tag` is metadata for filtering and analytics.
- `Blueprint` defines rules for generating tests.

## Why References Matter

Copying questions into multiple sets creates broken learning data:

- Correctness history diverges.
- Bookmarks apply to one copy but not another.
- AI chat attaches to the wrong duplicate.
- SRS schedules the same fact multiple times.
- Content fixes must be repeated.

The golden rule is: duplicate organization, not questions.

## Collection Types

| Type | Purpose | Ordered | Author/User Created | Example |
|------|---------|---------|---------------------|---------|
| `source` | Mirrors the imported book, syllabus, or official outline. | Yes | Author | Chapter 3 / Section 2 |
| `topic` | Groups questions by concepts or knowledge area. | Optional | Author or user | COLREG lights, cargo stability |
| `practice_set` | Curated fixed set for targeted practice. | Yes | Author or user | 50 common calculation questions |
| `exam_blueprint` | Defines draw rules for tests. | Rule-based | Author | 10 navigation, 20 management, difficulty 3+ |
| `smart` | Computed list from learner state. | Usually dynamic | System | Wrong questions, marked, due today |
| `playlist` | Learner-defined ordered queue. | Yes | User | Tonight's review list |

## Source Outline

The source outline should preserve the author's or publisher's structure. It is important for trust, citation, and finding material.

Rules:

- Preserve source order.
- Preserve original section names when available.
- Avoid using source sections as the only taxonomy.
- Treat each imported chapter/section as an implicit `source` collection.

## Topic Taxonomy

Topic collections organize conceptual learning. They may cross source boundaries.

Rules:

- A topic can include questions from multiple chapters.
- A question can belong to multiple topics.
- Topic names should be stable and human-readable.
- Tags can help discover topics, but tags are not a replacement for curated topic collections.

## Practice Sets

Practice sets are deliberate selections. They should be stable enough that users can resume, share, or compare progress within them.

Rules:

- Membership is explicit.
- Order may be explicit.
- Progress remains keyed by question ID.
- Removing a question from a set does not delete question history.

## Smart Collections

Smart collections are computed views. They should not store static membership except for caching.

Examples:

- Wrong questions.
- Marked questions.
- Unanswered questions.
- Due reviews.
- Low-confidence cards.
- Low-accuracy topic.

Rules:

- Definition is stored, not item copies.
- Results can change as progress changes.
- UI must make dynamic behavior clear.

## Exam Blueprints

Exam blueprints are not ordinary folders. They define selection rules for Test mode.

A blueprint may specify:

- Included collections.
- Excluded collections.
- Question count.
- Topic proportions.
- Difficulty range.
- New/wrong/marked constraints.
- Randomization seed policy.
- Time limit.

The output of a blueprint is a frozen test session. The blueprint may change later, but historical sessions must remain interpretable.

## Tags vs Collections

Tags answer: "What metadata does this item have?"

Collections answer: "Where does this item belong in a navigable or curated learning path?"

Use tags for:

- Concepts.
- Standards.
- Source attributes.
- Difficulty hints.
- Skills.
- Freeform labels.

Use collections for:

- Ordered source outlines.
- Curated practice sets.
- Learner playlists.
- Exam blueprints.
- Topic trees that should be browsed.

Do not build deep navigation from raw tags alone. Tag sets become inconsistent without curation.

## Collection Membership Rules

Membership should eventually be represented as:

```text
collection_id
question_id
position
role
metadata
```

Where `role` can distinguish:

- `item`: normal answerable question.
- `context`: supporting content.
- `optional`: extra practice.
- `anchor`: representative item for a topic.

Progress still attaches to `question_id`, not to `collection_id + position`.

## Migration Path

1. Keep importing `chapters -> sections -> questions`.
2. Treat each chapter and section as implicit source collections.
3. Keep existing `Book`, `Chapter`, and `Section` models until a real multi-collection UI exists.
4. Add explicit collection tables only when the app needs more than one hierarchy.
5. Introduce collection references without duplicating question rows.
6. Add blueprints after collection membership is stable.

## Design Smells

- The same question text appears as multiple database rows solely because it belongs to multiple sets.
- A source section is used as a topic taxonomy even when topics cross chapters.
- Smart collections store stale copies instead of query definitions.
- Test history stores only indexes, making it fragile after reordering.
- Bookmarks attach to collection positions instead of question IDs.
- Tags are used as a substitute for authored navigation.

## Acceptance Checklist

Before adding collection features, confirm:

- Questions are referenced, not copied.
- Source order can be preserved.
- A question can belong to multiple collections.
- Progress remains stable after reordering.
- Smart collections are dynamic and explainable.
- Test sessions freeze the selected items.
- Old packages still import into a useful source collection tree.
