/// Mirrors the backend's ServiceDuration enum - how long the job typically
/// takes, shown to the customer before they book.
enum ServiceDuration {
  oneToTwoHours,
  halfDay,
  fullDay;

  /// Matches the backend's exact enum constant names (Jackson serializes/
  /// deserializes Dart's lowerCamelCase names as-is otherwise, which
  /// wouldn't match Java's SCREAMING_SNAKE_CASE constants).
  String get wireName => switch (this) {
        ServiceDuration.oneToTwoHours => 'ONE_TO_TWO_HOURS',
        ServiceDuration.halfDay => 'HALF_DAY',
        ServiceDuration.fullDay => 'FULL_DAY',
      };

  String get label => switch (this) {
        ServiceDuration.oneToTwoHours => '1-2 hrs',
        ServiceDuration.halfDay => 'Half day',
        ServiceDuration.fullDay => 'Full day',
      };

  static ServiceDuration fromWireName(String wireName) => switch (wireName) {
        'HALF_DAY' => ServiceDuration.halfDay,
        'FULL_DAY' => ServiceDuration.fullDay,
        _ => ServiceDuration.oneToTwoHours,
      };
}
