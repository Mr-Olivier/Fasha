/// Mirrors the backend's CategoryResponse DTO. Fetched the same way for
/// everyone (GET /api/categories); only an admin can also create, rename,
/// or delete one, via AdminCategoryController.
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
