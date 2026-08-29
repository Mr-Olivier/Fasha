/// Mirrors the backend's `Role` enum (rw.kazilink.user.Role).
///
/// Dart convention is lowerCamelCase enum values, but the backend sends
/// "CUSTOMER"/"PROVIDER"/"ADMIN" over the wire (that's how Java enum names
/// look as JSON). Rather than let the wire format dictate our naming style,
/// we keep idiomatic Dart names here and convert explicitly at the edges -
/// see [UserRoleJson] below.
enum UserRole { customer, provider, admin }

extension UserRoleJson on UserRole {
  static UserRole fromWire(String value) => switch (value) {
        'CUSTOMER' => UserRole.customer,
        'PROVIDER' => UserRole.provider,
        'ADMIN' => UserRole.admin,
        _ => throw ArgumentError('Unknown role from server: $value'),
      };

  String toWire() => switch (this) {
        UserRole.customer => 'CUSTOMER',
        UserRole.provider => 'PROVIDER',
        UserRole.admin => 'ADMIN',
      };
}
