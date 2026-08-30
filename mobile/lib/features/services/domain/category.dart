/// Mirrors the backend's CategoryResponse DTO. Categories are read-only
/// from the app's point of view - managed by an admin, a feature that
/// doesn't exist yet.
class Category {
  const Category({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String? description;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
      );
}
