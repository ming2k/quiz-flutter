# SRS Spaced Repetition Algorithm

> Explains the SM-2 algorithm used in the app and its variant.

---

## 1. What is SM-2?

SM-2 (SuperMemo-2) is a spaced-repetition algorithm proposed by Piotr Wozniak in 1987. It dynamically adjusts the review interval of each card based on the user's self-rating (Again / Hard / Good / Easy) after every review, scheduling the next review just before the forgetting curve drops, thereby maximizing memory efficiency.

---

## 2. Core States

Each card in the SRS system is in one of four states:

| State | Code | Description |
|-------|------|-------------|
| New | `newCard` | Never reviewed before |
| Learning | `learning` | First review or after relearning; short intervals for consolidation |
| Review | `review` | Completed the learning stage; enters the normal interval cycle |
| Relearning | `relearning` | After pressing Again during review; returns to short intervals |

---

## 3. Data Structure

```dart
class SrsState {
  final String questionId;
  final String bookId;
  double intervalDays;      // Current interval (days)
  double easeFactor;        // Ease factor (default 2.5, min 1.3, max 2.5)
  int repetitions;          // Consecutive successful reviews
  int lapses;               // Number of times forgotten
  DateTime? dueDate;        // Next due date
  DateTime? lastReviewed;   // Last review timestamp
  SrsReviewState reviewState; // Card state
}
```

---

## 4. Algorithm Flow

### 4.1 Rating Input

After reviewing a card, the user selects one of four ratings:

| Rating | Effect |
|--------|--------|
| **Again** | Completely forgot; resets learning progress |
| **Hard** | Barely recalled; interval increases slightly |
| **Good** | Normal recall; standard interval increase |
| **Easy** | Effortless recall; large interval increase, ease goes up |

### 4.2 State Transition Rules

#### First rating for a new card

| Rating | interval | ease | reps | State |
|--------|----------|------|------|-------|
| Again | 1 day | 2.5 - 0.2 = 2.3 | 0 | relearning |
| Hard | 1 day | 2.5 | 1 | review |
| Good | 1 day | 2.5 | 1 | review |
| Easy | 4 days | min(2.5 + 0.15, 2.5) = 2.5 | 1 | review |

#### Rating a card in Review state

**Formula:**
```
newInterval = oldInterval * easeFactor
```

| Rating | interval | ease | reps | State |
|--------|----------|------|------|-------|
| Again | 1 day | ease - 0.2 | 0 | relearning |
| Hard | oldInterval * 1.2 | ease - 0.15 | reps + 1 | review |
| Good | oldInterval * ease | unchanged | reps + 1 | review |
| Easy | oldInterval * ease * 1.3 | ease + 0.15 | reps + 1 | review |

**Constraints:**
- `easeFactor` minimum is `1.3`, maximum is `2.5`.
- `interval` has no upper bound (can accumulate to months or years).

#### Rating a card in Relearning state

Cards in relearning are treated as new cards on the next rating, but historical `lapses` are preserved.

---

## 5. Daily Queue Construction

When entering Review mode each day, the queue is built as follows:

1. **Due cards**: `dueDate <= now()` and state is `learning` / `review` / `relearning`.
2. **New cards**: state is `newCard`, ordered by question ID, capped at 20 per day (configurable).
3. Queue order: due cards first, new cards appended.

---

## 6. Statistics Aggregation

Each book displays an SRS statistics badge on the home screen:

| Badge | Meaning |
|-------|---------|
| New `N` | Number of new cards |
| Learning `L` | Number of cards in learning |
| Due `R` | Number of review cards due today |

---

## 7. Differences from Anki

This implementation is a simplified SM-2. Key differences from Anki:

| Feature | This App | Anki |
|---------|----------|------|
| Learning steps | Fixed 1 day | Configurable (minute-level) |
| Daily new-card limit | Fixed 20 | Configurable |
| Lapse penalty | ease - 0.2 | ease - 0.2 |
| Delayed review compensation | None | Yes (interval adjusted for delay) |
| Card suspension | No | Yes |

---

## 8. References

- [SuperMemo: Incremental Learning](https://super-memory.com/help/read.htm)
- [Anki SM-2 Implementation](https://faqs.ankiweb.net/what-spaced-repetition-algorithm.html)
