/// Mirrors the backend's TimeWindow enum - the rough time of day a
/// customer prefers on the Request Service form.
enum TimeWindow { morning, afternoon, evening }

extension TimeWindowJson on TimeWindow {
  static TimeWindow fromWire(String value) => switch (value) {
        'MORNING' => TimeWindow.morning,
        'AFTERNOON' => TimeWindow.afternoon,
        'EVENING' => TimeWindow.evening,
        _ => throw ArgumentError('Unknown time window from server: $value'),
      };

  String toWire() => switch (this) {
        TimeWindow.morning => 'MORNING',
        TimeWindow.afternoon => 'AFTERNOON',
        TimeWindow.evening => 'EVENING',
      };

  String get label => switch (this) {
        TimeWindow.morning => 'Morning',
        TimeWindow.afternoon => 'Afternoon',
        TimeWindow.evening => 'Evening',
      };
}
