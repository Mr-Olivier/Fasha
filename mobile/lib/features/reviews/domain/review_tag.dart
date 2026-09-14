/// Mirrors the backend's ReviewTag enum - the "What stood out?" chips on
/// the Leave a Review screen.
enum ReviewTag { onTime, fairPrice, cleanWork, polite }

extension ReviewTagJson on ReviewTag {
  static ReviewTag fromWire(String value) => switch (value) {
        'ON_TIME' => ReviewTag.onTime,
        'FAIR_PRICE' => ReviewTag.fairPrice,
        'CLEAN_WORK' => ReviewTag.cleanWork,
        'POLITE' => ReviewTag.polite,
        _ => throw ArgumentError('Unknown review tag from server: $value'),
      };

  String toWire() => switch (this) {
        ReviewTag.onTime => 'ON_TIME',
        ReviewTag.fairPrice => 'FAIR_PRICE',
        ReviewTag.cleanWork => 'CLEAN_WORK',
        ReviewTag.polite => 'POLITE',
      };

  String get label => switch (this) {
        ReviewTag.onTime => 'On time',
        ReviewTag.fairPrice => 'Fair price',
        ReviewTag.cleanWork => 'Clean work',
        ReviewTag.polite => 'Polite',
      };
}
