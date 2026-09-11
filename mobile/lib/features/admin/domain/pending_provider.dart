import '../../providers/domain/verification_status.dart';
import 'account_status.dart';

/// Mirrors the backend's PendingProviderResponse - one row in the admin
/// provider-approval queue, with the owner's contact details and service
/// count already attached so the screen never needs a second round-trip
/// per provider just to render the list.
///
/// [ownerUserId]/[ownerAccountStatus] let AdminProvidersScreen suspend/
/// resume/delete this provider's underlying account (AdminUserController)
/// right from this same card.
class PendingProvider {
  const PendingProvider({
    required this.id,
    required this.businessName,
    this.description,
    this.location,
    required this.verificationStatus,
    required this.appliedAt,
    required this.ownerUserId,
    required this.ownerName,
    required this.ownerEmail,
    this.ownerPhone,
    required this.ownerAccountStatus,
    required this.serviceCount,
  });

  final String id;
  final String businessName;
  final String? description;
  final String? location;
  final VerificationStatus verificationStatus;
  final DateTime appliedAt;
  final String ownerUserId;
  final String ownerName;
  final String ownerEmail;
  final String? ownerPhone;
  final AccountStatus ownerAccountStatus;
  final int serviceCount;

  factory PendingProvider.fromJson(Map<String, dynamic> json) => PendingProvider(
        id: json['id'] as String,
        businessName: json['businessName'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        verificationStatus: VerificationStatusJson.fromWire(json['verificationStatus'] as String),
        appliedAt: DateTime.parse(json['appliedAt'] as String),
        ownerUserId: json['ownerUserId'] as String,
        ownerName: json['ownerName'] as String,
        ownerEmail: json['ownerEmail'] as String,
        ownerPhone: json['ownerPhone'] as String?,
        ownerAccountStatus: AccountStatusJson.fromWire(json['ownerAccountStatus'] as String),
        serviceCount: (json['serviceCount'] as num).toInt(),
      );
}
