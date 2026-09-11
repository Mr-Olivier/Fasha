import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/admin_category.dart';
import 'admin_category_controller.dart';
import 'admin_stats_controller.dart';

/// Fixed-order categorical palette (validated with the project's dataviz
/// skill: `validate_palette.js` - all-pairs clears the CVD/normal-vision
/// floors for the first 3 slots, the adjacent-pairlist for all 6). NEVER
/// reassign a slot by rank (e.g. "always slot 0 for whichever category is
/// biggest this week") - a color must keep meaning the same category
/// across refreshes, which is why _ProvidersByCategoryChart sorts data
/// first, then zips it against this fixed list by position.
const _categoricalLight = [
  Color(0xFF2A78D6), // blue
  Color(0xFFEB6834), // orange
  Color(0xFF1BAF7A), // aqua
  Color(0xFFEDA100), // yellow
  Color(0xFFE87BA4), // magenta
  Color(0xFF008300), // green
];
const _categoricalDark = [
  Color(0xFF3987E5),
  Color(0xFFD95926),
  Color(0xFF199E70),
  Color(0xFFC98500),
  Color(0xFFD55181),
  Color(0xFF008300),
];

List<Color> _categoricalPalette(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? _categoricalDark : _categoricalLight;

/// The admin Overview screen's three dashboard charts, stacked vertically:
/// bookings volume over time, provider supply by category, and platform
/// growth. Each is its own `ConsumerWidget` so a slow/failed chart never
/// blocks the other two or the stat row above them.
class AdminDashboardCharts extends StatelessWidget {
  const AdminDashboardCharts({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _BookingsTrendChart(),
        SizedBox(height: AppSpacing.md),
        _ProvidersByCategoryChart(),
        SizedBox(height: AppSpacing.md),
        _UserGrowthChart(),
      ],
    );
  }
}

/// Shared container every chart card renders inside - title, optional
/// subtitle, fixed-height body (loading/error/empty/chart), consistent
/// card chrome (AppRadii.card) matching every other card in the app.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, this.subtitle, this.legend, required this.child});

  final String title;
  final String? subtitle;
  final Widget? legend;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                    ],
                  ),
                ),
                if (legend != null) legend!,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(height: 180, child: child),
          ],
        ),
      ),
    );
  }
}

class _ChartMessage extends StatelessWidget {
  const _ChartMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}

/// A single time series (magnitude over time) - sequential/single-hue by
/// the dataviz skill's color formula, so this is the ONE chart here that
/// legitimately needs no legend (a lone series is named by its title).
class _BookingsTrendChart extends ConsumerWidget {
  const _BookingsTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsTrendProvider);
    final color = _categoricalPalette(context)[0];

    return _ChartCard(
      title: 'Bookings trend',
      subtitle: 'Last 30 days',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _ChartMessage('Could not load this chart.'),
        data: (points) {
          if (points.isEmpty) return const _ChartMessage('No bookings in this period yet.');

          final maxCount = points.map((p) => p.count).reduce((a, b) => a > b ? a : b);
          final step = (points.length / 5).ceil().clamp(1, points.length);

          return LineChart(
            LineChartData(
              minY: 0,
              maxY: maxCount < 4 ? 4 : maxCount + 1,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => FlLine(color: Theme.of(context).colorScheme.outline, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value != value.roundToDouble()) return const SizedBox.shrink();
                      return Text('${value.toInt()}', style: Theme.of(context).textTheme.labelSmall);
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    // Without an explicit interval, fl_chart auto-picks a
                    // FRACTIONAL one when the x-range is tiny (e.g. only 2
                    // points, range 0-1) - getTitlesWidget then gets called
                    // for in-between values too, and truncating those via
                    // toInt() collapsed several fractional ticks onto the
                    // same label (a real bug caught via live screenshot,
                    // not something the analyzer or a widget test would
                    // ever catch). Interval 1 restricts ticks to exactly
                    // the integer x-values our spots actually sit at.
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (value != value.roundToDouble() || i < 0 || i >= points.length || i % step != 0) {
                        return const SizedBox.shrink();
                      }
                      final d = points[i].date;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text('${d.day}/${d.month}', style: Theme.of(context).textTheme.labelSmall),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem('${s.y.toInt()} booking${s.y.toInt() == 1 ? '' : 's'}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].count.toDouble())],
                  isCurved: true,
                  color: color,
                  barWidth: 2.5,
                  dotData: FlDotData(show: points.length <= 14),
                  belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Categorical magnitude comparison across many categories - a ranked
/// horizontal bar list rather than a pie/donut: a pie's slices are all
/// mutually adjacent (an "all-pairs" color context), which only the first
/// 3 palette slots clear - a ranked bar list only needs ADJACENT rows to
/// stay distinct, so it comfortably supports the top 6 shown here. Each
/// row's name is a direct label, satisfying the palette's "relief" rule
/// for the slots that read under 3:1 contrast on a light surface.
class _ProvidersByCategoryChart extends ConsumerWidget {
  const _ProvidersByCategoryChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminCategoryControllerProvider);
    final palette = _categoricalPalette(context);

    return _ChartCard(
      title: 'Providers by category',
      subtitle: 'Top categories',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _ChartMessage('Could not load this chart.'),
        data: (categories) {
          final withProviders = categories.where((c) => c.providerCount > 0).toList()
            ..sort((a, b) => b.providerCount.compareTo(a.providerCount));
          final top = withProviders.take(6).toList();
          if (top.isEmpty) return const _ChartMessage('No providers approved yet.');

          final maxCount = top.first.providerCount;
          return ListView.separated(
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) => _CategoryBarRow(
              category: top[index],
              color: palette[index % palette.length],
              fraction: maxCount == 0 ? 0 : top[index].providerCount / maxCount,
            ),
          );
        },
      ),
    );
  }
}

class _CategoryBarRow extends StatelessWidget {
  const _CategoryBarRow({required this.category, required this.color, required this.fraction});

  final AdminCategory category;
  final Color color;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(category.name, style: textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 14,
                  width: constraints.maxWidth * fraction.clamp(0.04, 1.0),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 20,
          child: Text('${category.providerCount}', style: textTheme.labelSmall, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

/// Two series (customers vs providers) - categorical identity, so this
/// gets a legend (dot + label) and the first two FIXED palette slots,
/// never reassigned by which series happens to be bigger.
class _UserGrowthChart extends ConsumerWidget {
  const _UserGrowthChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userGrowthProvider);
    final palette = _categoricalPalette(context);
    final customerColor = palette[0];
    final providerColor = palette[1];

    return _ChartCard(
      title: 'User growth',
      subtitle: 'Last 12 weeks',
      legend: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: customerColor, label: 'Customers'),
          const SizedBox(width: AppSpacing.sm),
          _LegendDot(color: providerColor, label: 'Providers'),
        ],
      ),
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _ChartMessage('Could not load this chart.'),
        data: (points) {
          if (points.isEmpty) return const _ChartMessage('No new signups in this period yet.');

          final maxCount = points
              .map((p) => p.newCustomers > p.newProviders ? p.newCustomers : p.newProviders)
              .reduce((a, b) => a > b ? a : b);
          final step = (points.length / 5).ceil().clamp(1, points.length);

          return LineChart(
            LineChartData(
              minY: 0,
              maxY: maxCount < 4 ? 4 : maxCount + 1,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => FlLine(color: Theme.of(context).colorScheme.outline, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value != value.roundToDouble()) return const SizedBox.shrink();
                      return Text('${value.toInt()}', style: Theme.of(context).textTheme.labelSmall);
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    // Without an explicit interval, fl_chart auto-picks a
                    // FRACTIONAL one when the x-range is tiny (e.g. only 2
                    // points, range 0-1) - getTitlesWidget then gets called
                    // for in-between values too, and truncating those via
                    // toInt() collapsed several fractional ticks onto the
                    // same label (a real bug caught via live screenshot,
                    // not something the analyzer or a widget test would
                    // ever catch). Interval 1 restricts ticks to exactly
                    // the integer x-values our spots actually sit at.
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (value != value.roundToDouble() || i < 0 || i >= points.length || i % step != 0) {
                        return const SizedBox.shrink();
                      }
                      final d = points[i].weekStart;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text('${d.day}/${d.month}', style: Theme.of(context).textTheme.labelSmall),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem('${s.y.toInt()}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].newCustomers.toDouble())],
                  isCurved: true,
                  color: customerColor,
                  barWidth: 2.5,
                  dotData: FlDotData(show: points.length <= 14),
                ),
                LineChartBarData(
                  spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].newProviders.toDouble())],
                  isCurved: true,
                  color: providerColor,
                  barWidth: 2.5,
                  dotData: FlDotData(show: points.length <= 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
