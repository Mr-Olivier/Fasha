import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/status_colors.dart';
import '../domain/audit_log_entry.dart';
import 'admin_audit_controller.dart';

/// Read-only view of the admin action audit trail (see the backend's V21
/// migration comment) - who did what, to what, and when. Every admin
/// mutation that changes an account or category's state writes a row here
/// (AdminAuditService.record); this screen just lists the most recent ones.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesState = ref.watch(adminAuditLogProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity log')),
      body: entriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Could not load the activity log.')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text(
                  'No admin activity recorded yet.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminAuditLogProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _AuditLogRow(entry: entries[index]),
            ),
          );
        },
      ),
    );
  }
}

class _AuditLogRow extends StatelessWidget {
  const _AuditLogRow({required this.entry});

  final AuditLogEntry entry;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_months[local.month - 1]} ${local.year}, $hour:$minute';
  }

  /// "USER_SUSPENDED" -> "User suspended" - the backend records a stable,
  /// machine-shaped constant (see AdminAuditService call sites); this is
  /// the one place it becomes human-readable prose.
  static String _humanize(String action) {
    final words = action.split('_').map((w) => w.toLowerCase()).toList();
    if (words.isEmpty) return action;
    return '${words.first[0].toUpperCase()}${words.first.substring(1)} ${words.skip(1).join(' ')}'.trim();
  }

  Color _actionColor(BuildContext context) {
    if (entry.action.contains('DELETED') || entry.action.contains('REJECTED') || entry.action.contains('SUSPENDED')) {
      return StatusColors.negative(context);
    }
    if (entry.action.contains('APPROVED') || entry.action.contains('RESUMED') || entry.action.contains('CREATED')) {
      return StatusColors.positive(context);
    }
    return StatusColors.pending(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = _actionColor(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.bolt, color: color, size: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_humanize(entry.action), style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  if (entry.details != null && entry.details!.isNotEmpty)
                    Text(entry.details!, style: textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    'by ${entry.adminName} · ${_formatDateTime(entry.createdAt)}',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
