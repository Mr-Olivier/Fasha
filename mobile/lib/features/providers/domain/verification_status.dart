/// Mirrors the backend's VerificationStatus enum (rw.kazilink.provider).
/// A provider can never set this themselves - it only ever comes FROM the
/// server, which is why there's no toWire() here, only fromWire().
enum VerificationStatus { pending, approved, rejected }

extension VerificationStatusJson on VerificationStatus {
  static VerificationStatus fromWire(String value) => switch (value) {
        'PENDING' => VerificationStatus.pending,
        'APPROVED' => VerificationStatus.approved,
        'REJECTED' => VerificationStatus.rejected,
        _ => throw ArgumentError('Unknown verification status from server: $value'),
      };
}
