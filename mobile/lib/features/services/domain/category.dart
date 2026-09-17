/// Mirrors the backend's CategoryResponse DTO. Fetched the same way for
/// everyone (GET /api/categories); only an admin can also create, rename,
/// or delete one, via AdminCategoryController.
class Category {
  const Category({required this.id, required this.name, this.description, this.imageUrl});

  final String id;
  final String name;
  final String? description;

  /// Null until an admin uploads one (AdminCategoryController.uploadImage) -
  /// CategoryIconBadge falls back to CategoryStyle's name-matched default
  /// icon/colour whenever this is null, never an empty placeholder box.
  final String? imageUrl;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );
}
