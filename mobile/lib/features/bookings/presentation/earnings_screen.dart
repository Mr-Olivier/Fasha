import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/star_rating.dart';
import 'earnings_controller.dart';

/// D8 - "Completed jobs & earnings". [_period] drives both
/// earningsSummaryProvider and completedJobsProvider, kept as this
/// screen's own local state (not Riverpod state) since it's pure UI
/// selection, the same reasoning ProfileScreen's theme SegmentedButton
/// doesn't need its own controller either.
class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String _period = 'month';

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(earningsSummaryProvider(_period));
    final jobsState = ref.watch(completedJobsProvider(_period));
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Completed jobs')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summaryState.when(
              loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
              error: (error, _) => Text(
                'Could not load earnings.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              data: (summary) => DecoratedBox(
                decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(AppRadii.card)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earned ${summary.periodLabel}',
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'RWF ${summary.totalEarned.toStringAsFixed(0)}',
                              style: textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${summary.jobCount}',
                            style: textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary),
                          ),
                          Text('jobs', style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.8))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'month', label: Text('This month')),
                ButtonSegment(value: 'all', label: Text('All time')),
              ],
              selected: {_period},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => setState(() => _period = selection.first),
            ),
            const SizedBox(height: AppSpacing.gutter),
            jobsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Could not load completed jobs.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Text(
                    'No completed jobs yet.',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  );
                }
                return Column(
                  children: [
                    for (final job in jobs) ...[
                      Card(
                        child: ListTile(
                          title: Text(job.customerName),
                          subtitle: Text(
                            '${job.serviceName} · ${job.completedAt.year}-${job.completedAt.month.toString().padLeft(2, '0')}-${job.completedAt.day.toString().padLeft(2, '0')}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('RWF ${job.price.toStringAsFixed(0)}', style: textTheme.bodyMedium),
                              if (job.hasReview)
                                StarRating(rating: (job.rating ?? 0).toDouble(), size: 12)
                              else
                                Text(
                                  'NO REVIEW YET',
                                  style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
