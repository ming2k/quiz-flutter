# Learning Design Standard

This directory defines Mnema's target learning model. It is the product design standard for questions, study modes, question structure, and collection organization. It is deliberately more stable than the current Flutter implementation and more opinionated than the package protocol.

The package protocol answers: "What can Mnema import today?"

This design standard answers: "What should Mnema become, and which product constraints should remain true as it grows?"

## Design Authority

Use these documents when making decisions about:

- Package schema changes.
- SQLite or domain-model refactors.
- Practice, Test, Review, and Preview workflows.
- Question type support and grading behavior.
- Question bank organization and collection UI.
- Migration behavior for existing packages.

When implementation and these documents disagree, treat the mismatch as design debt. Do not silently expand behavior just because a package format can technically express it.

## Documents

| Document | Purpose |
|----------|---------|
| [Study Modes](study_modes.md) | Defines mode responsibilities, state effects, and eligibility rules. |
| [Question Types](question_types.md) | Defines answer semantics, grading expectations, and type-specific UX. |
| [Question Structure](question_structure.md) | Defines standalone items, shared passages, sub-questions, identity, and counting. |
| [Collection Model](collection_model.md) | Defines question banks, source outlines, curated collections, smart collections, tags, and future membership rules. |

## Core Vocabulary

| Term | Definition |
|------|------------|
| Question bank | A package-level content unit that owns questions, media, source metadata, and collection structure. |
| Answerable item | A unit the learner can answer, grade, schedule, bookmark, and discuss with AI. |
| Context container | Non-answerable content that supplies shared stimulus, such as a passage, chart, case, or scenario. |
| Question type | The semantic answer model of an answerable item, such as multiple choice, fill-in-the-blank, cloze, or flashcard. |
| Study mode | A workflow that decides how an item is presented, answered, scored, scheduled, and persisted. |
| Collection | A navigable or computed grouping of question references. Collections organize questions without duplicating question records. |
| Tag | Lightweight metadata used for filtering, search, and analytics. Tags are not a navigable hierarchy. |

## Non-Negotiable Principles

1. Question type and study mode are separate concepts.

   A multiple-choice item can appear in Practice, Test, and Review. A flashcard belongs primarily in Review. A passage belongs in no mode by itself.

2. Progress belongs to answerable items, not to presentation containers.

   Answers, bookmarks, AI chat sessions, SRS state, and test history attach to the leaf item the learner actually answers.

3. Passage parents are context, not questions.

   Passage parents must not be counted, scheduled, scored, or shown as standalone tasks. They may be previewed as content, but they are not learning work by themselves.

4. Auto-graded workflows require deterministic grading.

   Practice and Test may include only item types with defined grading rules. Importing a type is not enough to make it eligible for those modes.

5. Review may support self-rated recall.

   Review can handle flashcards, fill-in-the-blank, cloze, and other answer-reveal forms before they are auto-gradable, as long as the learner can reveal the answer and rate recall.

6. Collections organize references, not copies.

   One question may appear in a source section, a topic collection, a custom practice set, and a smart weak-area list. It remains one question with one progress history.

7. The source outline is preserved but not privileged forever.

   Imported chapters and sections are valuable because they reflect the source. They should not prevent topic taxonomies, exam blueprints, or learner-created sets.

8. Compatibility is a constraint, not a design ceiling.

   Current packages using `chapters -> sections -> questions` must continue working. Future design should not be limited to that two-level tree.

## Quality Bar

A proposed feature or schema change is not ready until it answers these questions:

- Which answerable item does progress attach to?
- Is the item eligible for Preview, Practice, Test, Review, or some subset?
- Is grading deterministic or self-rated?
- How are passage/context parents counted?
- How does the item behave when shuffled, filtered, bookmarked, reviewed, and included in a test?
- Does the design duplicate questions or reference them?
- How does it migrate or preserve old package behavior?
- What is the smallest protocol change that expresses the concept without leaking UI implementation details?

## Current Implementation Boundary

Protocol 2.0 and the current Flutter app implement part of this standard:

- Choice-based questions are supported in Practice, Test, and Review.
- Answer-reveal items can be imported and reviewed.
- Passage parents can hold shared content for child questions.
- SRS excludes passage parents.
- The storage model still uses `Book -> Chapter -> Section -> Question` as the compatibility hierarchy.

The collection model in this directory is therefore a target architecture, not a declaration that all collection tables or UI already exist.
