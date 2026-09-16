/// Mirrors the backend's BookingStatus enum (rw.kazilink.booking). See that
/// enum's doc comment for the full state diagram this represents.
enum BookingStatus { requested, accepted, rejected, inProgress, completed, cancelled, reviewed }

/// The standard happy-path stages every booking passes through in order.
/// REJECTED/CANCELLED aren't in this list - they're terminal branches off
/// it (see BookingTrackerScreen's _Timeline and MyBookingsScreen's
/// BookingCard, the two places that render progress along this path)
/// rather than something a booking "makes progress" toward.
const bookingHappyPathStages = [
  BookingStatus.requested,
  BookingStatus.accepted,
  BookingStatus.inProgress,
  BookingStatus.completed,
  BookingStatus.reviewed,
];

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
