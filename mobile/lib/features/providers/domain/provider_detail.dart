import '../../services/domain/service_listing.dart';
import 'provider_profile.dart';

/// Mirrors the backend's ProviderDetailResponse DTO - a provider's public
/// profile plus every service they offer. Returned by GET /api/providers/{id}.
class ProviderDetail {
  const ProviderDetail({required this.profile, required this.services});

  final ProviderProfile profile;
  final List<ServiceListing> services;

  factory ProviderDetail.fromJson(Map<String, dynamic> json) => ProviderDetail(
        profile: ProviderProfile.fromJson(json['profile'] as Map<String, dynamic>),
        services: (json['services'] as List<dynamic>)
            .map((e) => ServiceListing.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
