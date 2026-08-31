import '../../auth/domain/user_role.dart';

/// Mirrors the backend's UserResponse DTO - the shape returned by
/// GET/PATCH /api/users/me and the avatar upload endpoint.
///
/// Deliberately separate from AuthUser (auth feature): this has no [token]
/// field, because none of those endpoints touch or return one - only
/// login/register do. AuthController.applyAccountUpdate is what merges an
/// account snapshot like this back into the cached, logged-in AuthUser.
class UserAccount {
  const UserAccount({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profileImageUrl,
  });

  final String userId;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? profileImageUrl;

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: UserRoleJson.fromWire(json['role'] as String),
        profileImageUrl: json['profileImageUrl'] as String?,
      );
}
