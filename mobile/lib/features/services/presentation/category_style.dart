import 'package:flutter/material.dart';

/// Pairs a category name with an icon and an accent colour, so Home's
/// category rail reads like a real marketplace app - Jiji, Urban Company,
/// and SafeBoda all give each category its own icon + colour rather than
/// plain text, the same way Instagram/Facebook give each Story/category a
/// distinct visual identity instead of a bare label.
///
/// This mapping lives entirely on the Flutter side (the backend Category
/// has no icon/colour column) so adding a category never needs a backend
/// migration - a name the map doesn't recognise (e.g. one an admin creates
/// later) just falls back to a generic icon in a neutral colour.
class CategoryStyle {
  const CategoryStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static const _fallback = CategoryStyle(icon: Icons.category_outlined, color: Color(0xFF64748B));

  static const Map<String, CategoryStyle> _byName = {
    'Electrician': CategoryStyle(icon: Icons.electrical_services, color: Color(0xFFD97706)),
    'Plumber': CategoryStyle(icon: Icons.plumbing, color: Color(0xFF3B82C4)),
    'Mechanic': CategoryStyle(icon: Icons.build, color: Color(0xFF6B7280)),
    // Deliberately NOT the app's own primary green (#0B6B4F) - that colour
    // means "selected/primary action" everywhere else in the app (see
    // AppTheme), so reusing it here would make this bubble look like a
    // selected state instead of just one more category among many.
    'Cleaner': CategoryStyle(icon: Icons.cleaning_services, color: Color(0xFF0D9488)),
    'Painter': CategoryStyle(icon: Icons.format_paint, color: Color(0xFFC2410C)),
    'Tutor': CategoryStyle(icon: Icons.menu_book, color: Color(0xFF7C3AED)),
    'Tailor': CategoryStyle(icon: Icons.checkroom, color: Color(0xFFDB2777)),
    'Phone & Computer Repair': CategoryStyle(icon: Icons.devices_other, color: Color(0xFF2563EB)),
    'Carpenter': CategoryStyle(icon: Icons.carpenter, color: Color(0xFF92400E)),
    'Hair & Beauty': CategoryStyle(icon: Icons.face_retouching_natural, color: Color(0xFFEC4899)),
    'Photographer': CategoryStyle(icon: Icons.camera_alt, color: Color(0xFF0F172A)),
    'Event Planner': CategoryStyle(icon: Icons.celebration, color: Color(0xFFE11D48)),
    'Mover': CategoryStyle(icon: Icons.local_shipping, color: Color(0xFF0891B2)),
    'Gardener': CategoryStyle(icon: Icons.yard, color: Color(0xFF16A34A)),
    'Mason': CategoryStyle(icon: Icons.foundation, color: Color(0xFF78716C)),
    'Laundry': CategoryStyle(icon: Icons.local_laundry_service, color: Color(0xFF0EA5E9)),
    'Caterer': CategoryStyle(icon: Icons.restaurant, color: Color(0xFFEA580C)),
    'Security Guard': CategoryStyle(icon: Icons.shield, color: Color(0xFF1E3A8A)),
  };

  static CategoryStyle of(String categoryName) => _byName[categoryName] ?? _fallback;
}
