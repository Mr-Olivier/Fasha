import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/earnings_api.dart';
import '../data/earnings_repository.dart';
import '../domain/completed_job.dart';
import '../domain/earnings_summary.dart';

final earningsApiProvider = Provider<EarningsApi>(
  (ref) => EarningsApi(ref.watch(apiClientProvider).dio),
);

final earningsRepositoryProvider = Provider<EarningsRepository>(
  (ref) => EarningsRepository(ref.watch(earningsApiProvider)),
);

/// Keyed by period ("month" or "all") - EarningsScreen's SegmentedButton
/// switches which family member it watches, rather than one controller
/// juggling two states itself.
final earningsSummaryProvider = FutureProvider.family<EarningsSummary, String>(
  (ref, period) => ref.watch(earningsRepositoryProvider).getSummary(period),
);

final completedJobsProvider = FutureProvider.family<List<CompletedJob>, String>(
  (ref, period) => ref.watch(earningsRepositoryProvider).listCompletedJobs(period),
);
