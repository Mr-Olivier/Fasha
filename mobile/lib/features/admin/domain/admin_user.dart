import '../../auth/domain/user_role.dart';
import 'account_status.dart';

/// Mirrors the backend's AdminUserResponse - one row in the admin
/// Customers/Providers account list (GET /api/admin/users?role=...).
class AdminUser {
  const AdminUser({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.profileImageUrl,
    required this.createdAt,
  });

  final String userId;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final AccountStatus status;
  final String? profileImageUrl;
  final DateTime createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: UserRoleJson.fromWire(json['role'] as String),
        status: AccountStatusJson.fromWire(json['status'] as String),
        profileImageUrl: json['profileImageUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
