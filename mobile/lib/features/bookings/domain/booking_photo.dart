/// Who attached a BookingPhoto - mirrors the backend's PhotoUploaderRole.
enum PhotoUploaderRole { customer, provider }

extension PhotoUploaderRoleJson on PhotoUploaderRole {
  static PhotoUploaderRole fromWire(String value) => switch (value) {
        'CUSTOMER' => PhotoUploaderRole.customer,
        _ => PhotoUploaderRole.provider,
      };
}

/// Mirrors the backend's BookingPhotoResponse DTO - metadata only. The
/// actual image bytes are fetched separately (see SecureNetworkImage)
/// against GET /api/bookings/{bookingId}/photos/{id}.
class BookingPhoto {
  const BookingPhoto({required this.id, required this.uploadedByRole, required this.createdAt});

  final String id;
  final PhotoUploaderRole uploadedByRole;
  final DateTime createdAt;

  factory BookingPhoto.fromJson(Map<String, dynamic> json) => BookingPhoto(
        id: json['id'] as String,
        uploadedByRole: PhotoUploaderRoleJson.fromWire(json['uploadedByRole'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
