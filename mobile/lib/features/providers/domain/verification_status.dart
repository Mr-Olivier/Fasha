/// Mirrors the backend's VerificationStatus enum (rw.kazilink.provider).
/// A provider can never set this themselves - it only ever comes FROM the
/// server as part of their own profile. The one exception is the admin
/// approval screen, which needs toWire() to send `?status=PENDING` back.
enum VerificationStatus { pending, approved, rejected }

extension VerificationStatusJson on VerificationStatus {
  static VerificationStatus fromWire(String value) => switch (value) {
        'PENDING' => VerificationStatus.pending,
        'APPROVED' => VerificationStatus.approved,
        'REJECTED' => VerificationStatus.rejected,
        _ => throw ArgumentError('Unknown verification status from server: $value'),
      };

  String toWire() => switch (this) {
        VerificationStatus.pending => 'PENDING',
        VerificationStatus.approved => 'APPROVED',
        VerificationStatus.rejected => 'REJECTED',
      };
}
