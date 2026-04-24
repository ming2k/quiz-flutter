/// Events that can trigger feedback (sound + haptic).
///
/// [correct] is the default when continuous feedback is disabled.
/// [streak1] through [streakAce] are used when continuous feedback is enabled.
enum FeedbackEvent {
  correct,
  wrong,
  streak1,
  streak2,
  streak3,
  streak4,
  streak5,
  streakAce,
}
