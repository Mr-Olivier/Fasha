/// Mirrors the backend's BookingTrendPoint - one point on the admin
/// dashboard's "Bookings trend" chart.
class BookingTrendPoint {
  const BookingTrendPoint({required this.date, required this.count});

  final DateTime date;
  final int count;

  factory BookingTrendPoint.fromJson(Map<String, dynamic> json) => BookingTrendPoint(
        date: DateTime.parse(json['date'] as String),
        count: (json['count'] as num).toInt(),
      );
}
