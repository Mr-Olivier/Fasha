import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/admin_stats_api.dart';
import '../data/admin_stats_repository.dart';
import '../domain/admin_stats.dart';
import '../domain/booking_trend_point.dart';
import '../domain/user_growth_point.dart';

final adminStatsApiProvider = Provider<AdminStatsApi>(
  (ref) => AdminStatsApi(ref.watch(apiClientProvider).dio),
);

final adminStatsRepositoryProvider = Provider<AdminStatsRepository>(
  (ref) => AdminStatsRepository(ref.watch(adminStatsApiProvider)),
);

/// The admin Overview screen's stat row - read-only, so a plain
/// FutureProvider is enough (no mutations to coordinate, unlike
/// pendingProvidersProvider's decide/approve flow).
final adminStatsProvider = FutureProvider<AdminStats>(
  (ref) => ref.watch(adminStatsRepositoryProvider).getStats(),
);

/// Backs the admin dashboard's "Bookings trend" chart.
final bookingsTrendProvider = FutureProvider<List<BookingTrendPoint>>(
  (ref) => ref.watch(adminStatsRepositoryProvider).getBookingsTrend(),
);

/// Backs the admin dashboard's "User growth" chart.
final userGrowthProvider = FutureProvider<List<UserGrowthPoint>>(
  (ref) => ref.watch(adminStatsRepositoryProvider).getUserGrowth(),
);
