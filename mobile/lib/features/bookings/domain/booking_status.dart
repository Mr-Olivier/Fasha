/// Mirrors the backend's BookingStatus enum (rw.kazilink.booking). See that
/// enum's doc comment for the full state diagram this represents.
enum BookingStatus { requested, accepted, rejected, inProgress, completed, cancelled, reviewed }

extension BookingStatusJson on BookingStatus {
  static BookingStatus fromWire(String value) => switch (value) {
        'REQUESTED' => BookingStatus.requested,
        'ACCEPTED' => BookingStatus.accepted,
        'REJECTED' => BookingStatus.rejected,
        'IN_PROGRESS' => BookingStatus.inProgress,
        'COMPLETED' => BookingStatus.completed,
        'CANCELLED' => BookingStatus.cancelled,
        'REVIEWED' => BookingStatus.reviewed,
        _ => throw ArgumentError('Unknown booking status from server: $value'),
      };
}
