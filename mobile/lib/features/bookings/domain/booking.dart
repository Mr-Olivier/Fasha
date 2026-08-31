import 'booking_status.dart';

/// Mirrors the backend's BookingResponse DTO. Includes denormalized
/// display fields (customerName, providerBusinessName, serviceName,
/// servicePrice) the backend looks up for us - see BookingResponse's own
/// doc comment for why, on the Spring side.
class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.providerProfileId,
    required this.providerBusinessName,
    required this.serviceListingId,
    required this.serviceName,
    required this.servicePrice,
    this.note,
    this.requestedDate,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String providerProfileId;
  final String providerBusinessName;
  final String serviceListingId;
  final String serviceName;
  final double servicePrice;
  final String? note;
  final DateTime? requestedDate;
  final BookingStatus status;
  final DateTime createdAt;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        providerProfileId: json['providerProfileId'] as String,
        providerBusinessName: json['providerBusinessName'] as String,
        serviceListingId: json['serviceListingId'] as String,
        serviceName: json['serviceName'] as String,
        servicePrice: (json['servicePrice'] as num).toDouble(),
        note: json['note'] as String?,
        requestedDate: json['requestedDate'] != null ? DateTime.parse(json['requestedDate'] as String) : null,
        status: BookingStatusJson.fromWire(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
