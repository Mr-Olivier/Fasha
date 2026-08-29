import 'user_role.dart';

/// The logged-in user, mirroring the backend's AuthResponse DTO.
///
/// We deliberately keep the JWT [token] as part of this model (rather than
/// storing it separately) so that AuthSessionStorage only has one thing to
/// save/load - see its Javadoc-style comment for why we cache the whole
/// user instead of decoding the token or calling a "/me" endpoint.
class AuthUser {
  const AuthUser({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  final String token;
  final String userId;
  final String name;
  final String email;
  final UserRole role;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        token: json['token'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRoleJson.fromWire(json['role'] as String),
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'name': name,
        'email': email,
        'role': role.toWire(),
      };
}
