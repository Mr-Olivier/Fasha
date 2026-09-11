/// Mirrors the backend's UserGrowthPoint - one point on the admin
/// dashboard's "User growth" chart.
class UserGrowthPoint {
  const UserGrowthPoint({required this.weekStart, required this.newCustomers, required this.newProviders});

  final DateTime weekStart;
  final int newCustomers;
  final int newProviders;

  factory UserGrowthPoint.fromJson(Map<String, dynamic> json) => UserGrowthPoint(
        weekStart: DateTime.parse(json['weekStart'] as String),
        newCustomers: (json['newCustomers'] as num).toInt(),
        newProviders: (json['newProviders'] as num).toInt(),
      );
}
