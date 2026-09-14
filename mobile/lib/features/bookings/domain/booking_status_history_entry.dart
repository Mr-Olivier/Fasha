import 'booking_status.dart';

/// One row of Booking.statusHistory - mirrors the backend's
/// BookingStatusHistoryEntry. Powers the Booking Tracker screen's timeline
/// (Requested/Accepted/Started/Completed, each with its own timestamp) -
/// see V30__create_booking_status_history.sql on the backend for why this
/// couldn't just be derived from Booking.updatedAt.
class BookingStatusHistoryEntry {
  const BookingStatusHistoryEntry({required this.status, required this.changedAt});

  final BookingStatus status;
  final DateTime changedAt;

  factory BookingStatusHistoryEntry.fromJson(Map<String, dynamic> json) => BookingStatusHistoryEntry(
        status: BookingStatusJson.fromWire(json['status'] as String),
        changedAt: DateTime.parse(json['changedAt'] as String),
      );
}
