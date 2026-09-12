import 'service_duration.dart';

/// Mirrors the backend's ServiceListingResponse DTO.
///
/// [price] is a `double` here, not a fixed-point/decimal type. The backend
/// stores it as NUMERIC (exact decimal) precisely to avoid binary
/// floating-point error - that still matters there because it does the
/// actual money math. On this side we only ever display it or send it back
/// unchanged in a form, never add/subtract amounts, so a double is a fair
/// simplification for now; revisit if the app ever needs to do arithmetic
/// on prices client-side.
class ServiceListing {
  const ServiceListing({
    required this.id,
    required this.providerProfileId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    required this.visible,
  });

  final String id;
  final String providerProfileId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final ServiceDuration duration;

  /// Whether this service shows up in customer-facing browse/search - the
  /// "Show in search" toggle on the Add/Edit service form.
  final bool visible;

  factory ServiceListing.fromJson(Map<String, dynamic> json) => ServiceListing(
        id: json['id'] as String,
        providerProfileId: json['providerProfileId'] as String,
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        duration: ServiceDuration.fromWireName(json['duration'] as String),
        visible: json['visible'] as bool,
      );
}
