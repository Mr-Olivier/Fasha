import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/admin_audit_api.dart';
import '../data/admin_audit_repository.dart';
import '../domain/audit_log_entry.dart';

final adminAuditApiProvider = Provider<AdminAuditApi>(
  (ref) => AdminAuditApi(ref.watch(apiClientProvider).dio),
);

final adminAuditRepositoryProvider = Provider<AdminAuditRepository>(
  (ref) => AdminAuditRepository(ref.watch(adminAuditApiProvider)),
);

final adminAuditLogProvider = FutureProvider<List<AuditLogEntry>>(
  (ref) => ref.watch(adminAuditRepositoryProvider).list(),
);
