import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../services/domain/service_listing.dart';
import 'booking_controller.dart';

/// A customer requesting a specific service from ProviderDetailScreen.
/// [service] arrives via GoRoute's `extra` - same pattern ServiceFormScreen
/// uses for the ServiceListing it's editing.
class RequestBookingScreen extends ConsumerStatefulWidget {
  const RequestBookingScreen({super.key, required this.service});

  final ServiceListing service;

  @override
  ConsumerState<RequestBookingScreen> createState() => _RequestBookingScreenState();
}

class _RequestBookingScreenState extends ConsumerState<RequestBookingScreen> {
  final _noteController = TextEditingController();
  DateTime? _requestedDate;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _requestedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _requestedDate = picked);
  }

  Future<void> _submit() async {
    await ref.read(myBookingsControllerProvider.notifier).requestBooking(
          serviceListingId: widget.service.id,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          requestedDate: _requestedDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myBookingsControllerProvider);
    final isLoading = state.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(myBookingsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        final message = error is ApiException ? error.message : 'Something went wrong.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      final wasLoading = previous?.isLoading ?? false;
      if (wasLoading && next.hasValue && error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent.')));
        context.go('/my-bookings');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Request service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.service.name, style: textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'RWF ${widget.service.price.toStringAsFixed(0)}',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              TextField(
                controller: _noteController,
                enabled: !isLoading,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe what you need (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: isLoading ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _requestedDate == null
                      ? 'Pick a preferred date (optional)'
                      : '${_requestedDate!.year}-${_requestedDate!.month.toString().padLeft(2, '0')}-${_requestedDate!.day.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
