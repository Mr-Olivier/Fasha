/// Mirrors the backend's AdminStatsResponse - the four numbers on the admin
/// Overview screen's stat row.
class AdminStats {
  const AdminStats({
    required this.pendingApprovals,
    required this.activeProviders,
    required this.totalCustomers,
    required this.bookingsLast30Days,
  });

  final int pendingApprovals;
  final int activeProviders;
  final int totalCustomers;
  final int bookingsLast30Days;

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        pendingApprovals: (json['pendingApprovals'] as num).toInt(),
        activeProviders: (json['activeProviders'] as num).toInt(),
        totalCustomers: (json['totalCustomers'] as num).toInt(),
        bookingsLast30Days: (json['bookingsLast30Days'] as num).toInt(),
      );
}
