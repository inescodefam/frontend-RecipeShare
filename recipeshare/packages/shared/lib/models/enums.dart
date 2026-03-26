enum Difficulty { easy, medium, hard }

enum CategoryTagType { category, tag }

/// What is being reported: a recipe, a user profile, or a specific comment.
enum ReportTargetType { recipe, user, comment }

enum ReportReason { spam, offensive, inappropriate }

enum ReportStatus { pending, approved, rejected }

T enumFromString<T extends Enum>(
  List<T> values,
  String raw, {
  required T fallback,
}) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}