import 'booking_status.dart';
import 'booking_status_history_entry.dart';
import 'time_window.dart';

/// Mirrors the backend's BookingResponse DTO. Includes denormalized
/// display fields (customerName, providerBusinessName, serviceName,
/// servicePrice) the backend looks up for us - see BookingResponse's own
/// doc comment for why, on the Spring side.
class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.providerProfileId,
    required this.providerBusinessName,
    this.providerPhone,
    required this.serviceListingId,
    required this.serviceName,
    required this.servicePrice,
    this.note,
    this.requestedDate,
    this.address,
    this.timeWindow,
    required this.status,
    this.workNote,
    this.cancellationReason,
    this.statusHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String providerProfileId;
  final String providerBusinessName;
  final String? providerPhone;
  final String serviceListingId;
  final String serviceName;
  final double servicePrice;
  final String? note;
  final DateTime? requestedDate;
  final String? address;
  final TimeWindow? timeWindow;
  final BookingStatus status;
  final String? workNote;
  final String? cancellationReason;

  /// One entry per status this booking has passed through, oldest first -
  /// powers the Booking Tracker screen's timeline. See
  /// BookingStatusHistoryEntry's doc comment.
  final List<BookingStatusHistoryEntry> statusHistory;
  final DateTime createdAt;

  /// When this booking last changed status - e.g. the moment a provider
  /// tapped "Start job" (ACCEPTED -> IN_PROGRESS), since a COMPLETED
  /// booking never updates again after that. Used to compute "elapsed"
  /// time on ActiveJobScreen (D3) - createdAt would be when the REQUEST
  /// was made, not when work actually started.
  final DateTime updatedAt;

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String?,
        providerProfileId: json['providerProfileId'] as String,
        providerBusinessName: json['providerBusinessName'] as String,
        providerPhone: json['providerPhone'] as String?,
        serviceListingId: json['serviceListingId'] as String,
        serviceName: json['serviceName'] as String,
        servicePrice: (json['servicePrice'] as num).toDouble(),
        note: json['note'] as String?,
        requestedDate: json['requestedDate'] != null ? DateTime.parse(json['requestedDate'] as String) : null,
        address: json['address'] as String?,
        timeWindow: json['timeWindow'] != null ? TimeWindowJson.fromWire(json['timeWindow'] as String) : null,
        status: BookingStatusJson.fromWire(json['status'] as String),
        workNote: json['workNote'] as String?,
        cancellationReason: json['cancellationReason'] as String?,
        statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
            .map((e) => BookingStatusHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
