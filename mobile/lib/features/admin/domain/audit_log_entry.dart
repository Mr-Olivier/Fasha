/// Mirrors the backend's AdminAuditLogResponse - one row in the admin
/// Activity log (GET /api/admin/audit-log).
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.adminName,
    required this.action,
    required this.targetType,
    this.targetId,
    this.details,
    required this.createdAt,
  });

  final String id;
  final String adminName;
  final String action;
  final String targetType;
  final String? targetId;
  final String? details;
  final DateTime createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'] as String,
        adminName: json['adminName'] as String,
        action: json['action'] as String,
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String?,
        details: json['details'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
