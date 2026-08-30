import 'verification_status.dart';

/// Mirrors the backend's ProviderProfileResponse DTO.
class ProviderProfile {
  const ProviderProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.description,
    this.location,
    this.profileImageUrl,
    required this.verificationStatus,
  });

  final String id;
  final String userId;
  final String businessName;
  final String? description;
  final String? location;
  final String? profileImageUrl;
  final VerificationStatus verificationStatus;

  factory ProviderProfile.fromJson(Map<String, dynamic> json) => ProviderProfile(
        id: json['id'] as String,
        userId: json['userId'] as String,
        businessName: json['businessName'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        verificationStatus: VerificationStatusJson.fromWire(json['verificationStatus'] as String),
      );
}
