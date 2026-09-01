import 'user_role.dart';

/// The logged-in user, mirroring the backend's AuthResponse DTO (plus
/// [phone]/[profileImageUrl], which only GET /api/users/me and the profile
/// edit endpoints return - register/login don't, so they start out null
/// right after login and get filled in the first time ProfileScreen loads).
///
/// We deliberately keep the JWT [token] as part of this model (rather than
/// storing it separately) so that AuthSessionStorage only has one thing to
/// save/load, and so every screen that needs "who's logged in" (HomeScreen's
/// greeting, ProfileScreen, ...) reads the same single source of truth -
/// see AuthController.applyAccountUpdate for how a profile edit flows back
/// into this cached copy.
class AuthUser {
  const AuthUser({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.emailVerified,
    this.phone,
    this.profileImageUrl,
  });

  final String token;
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final bool emailVerified;
  final String? phone;
  final String? profileImageUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        token: json['token'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRoleJson.fromWire(json['role'] as String),
        emailVerified: json['emailVerified'] as bool,
        phone: json['phone'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'name': name,
        'email': email,
        'role': role.toWire(),
        'emailVerified': emailVerified,
        'phone': phone,
        'profileImageUrl': profileImageUrl,
      };
}
