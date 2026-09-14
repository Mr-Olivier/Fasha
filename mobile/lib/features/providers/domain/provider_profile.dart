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
    this.categoryId,
    this.yearsExperience,
    required this.verificationStatus,
    this.averageRating,
    this.reviewCount = 0,
    this.isFavorited = false,
  });

  final String id;
  final String userId;
  final String businessName;
  final String? description;
  final String? location;
  final String? profileImageUrl;
  final String? categoryId;
  final int? yearsExperience;
  final VerificationStatus verificationStatus;
  /// Null (not 0) when the provider has no reviews yet.
  final double? averageRating;
  final int reviewCount;

  /// True only when this response was built for a logged-in customer who
  /// favorited this provider - see backend ProviderProfileResponse's doc
  /// comment. Always false on a provider's own profile.
  final bool isFavorited;

  factory ProviderProfile.fromJson(Map<String, dynamic> json) => ProviderProfile(
        id: json['id'] as String,
        userId: json['userId'] as String,
        businessName: json['businessName'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        categoryId: json['categoryId'] as String?,
        yearsExperience: (json['yearsExperience'] as num?)?.toInt(),
        verificationStatus: VerificationStatusJson.fromWire(json['verificationStatus'] as String),
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        isFavorited: json['isFavorited'] as bool? ?? false,
      );

  ProviderProfile copyWith({bool? isFavorited}) => ProviderProfile(
        id: id,
        userId: userId,
        businessName: businessName,
        description: description,
        location: location,
        profileImageUrl: profileImageUrl,
        categoryId: categoryId,
        yearsExperience: yearsExperience,
        verificationStatus: verificationStatus,
        averageRating: averageRating,
        reviewCount: reviewCount,
        isFavorited: isFavorited ?? this.isFavorited,
      );
}
