/// Mirrors the backend's UserStatus enum (rw.kazilink.user). SUSPENDED
/// blocks the account from logging in (AuthService.login) and, for a
/// provider, drops them out of public search too - see
/// ProviderProfileService.excludeSuspendedOwners.
enum AccountStatus { active, suspended }

extension AccountStatusJson on AccountStatus {
  static AccountStatus fromWire(String value) => switch (value) {
        'ACTIVE' => AccountStatus.active,
        'SUSPENDED' => AccountStatus.suspended,
        _ => throw ArgumentError('Unknown account status from server: $value'),
      };

  String toWire() => switch (this) {
        AccountStatus.active => 'ACTIVE',
        AccountStatus.suspended => 'SUSPENDED',
      };
}
