/// Mirrors the backend's EarningsSummaryResponse DTO.
class EarningsSummary {
  const EarningsSummary({required this.totalEarned, required this.jobCount, required this.periodLabel});

  final double totalEarned;
  final int jobCount;
  final String periodLabel;

  factory EarningsSummary.fromJson(Map<String, dynamic> json) => EarningsSummary(
        totalEarned: (json['totalEarned'] as num).toDouble(),
        jobCount: (json['jobCount'] as num).toInt(),
        periodLabel: json['periodLabel'] as String,
      );
}
