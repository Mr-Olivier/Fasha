/// Mirrors the backend's AdminCategoryResponse - the admin category list's
/// richer shape (GET /api/admin/categories). Unlike [Category] (the public
/// GET /api/categories shape customers see), this includes categories an
/// admin has hidden, plus how many approved providers/bookings sit under
/// each one.
class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    this.description,
    required this.active,
    required this.providerCount,
    required this.bookingCount,
  });

  final String id;
  final String name;
  final String? description;
  final bool active;
  final int providerCount;
  final int bookingCount;

  factory AdminCategory.fromJson(Map<String, dynamic> json) => AdminCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        active: json['active'] as bool,
        providerCount: (json['providerCount'] as num).toInt(),
        bookingCount: (json['bookingCount'] as num).toInt(),
      );
}
