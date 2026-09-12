import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/provider_documents.dart';
import '../domain/verification_status.dart';
import 'provider_documents_controller.dart';

/// D7 - a provider uploads their ID/passport (required), an optional trade
/// certificate, and a selfie holding their ID (required), then submits for
/// admin review. Files are stored privately (SecureFileStorageService) -
/// this screen only ever shows whether each slot is uploaded, never the
/// documents themselves.
class GetVerifiedScreen extends ConsumerWidget {
  const GetVerifiedScreen({super.key});

  Future<void> _pickAndUpload(WidgetRef ref, BuildContext context, Future<void> Function(XFile) upload) async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (image == null) return;
    await upload(image);
    if (!context.mounted) return;
    final state = ref.read(providerDocumentsControllerProvider);
    if (state.hasError) AppToast.apiError(context, state.error!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsState = ref.watch(providerDocumentsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(providerDocumentsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Get verified')),
      body: documentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load your verification status.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
        data: (documents) {
          final isSaving = documentsState.isLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBanner(documents: documents),
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  'Verified providers appear higher in search and carry the green badge. We check your identity and, '
                  'for companies, your RDB registration.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: AppSpacing.gutter),
                _DocumentRow(
                  title: 'National ID or passport',
                  uploaded: documents.idDocumentUploaded,
                  onTap: isSaving ? null : () => _pickAndUpload(ref, context, notifier.uploadId),
                ),
                const SizedBox(height: AppSpacing.md),
                _DocumentRow(
                  title: 'Trade certificate · optional',
                  uploaded: documents.tradeCertificateUploaded,
                  onTap: isSaving ? null : () => _pickAndUpload(ref, context, notifier.uploadTradeCertificate),
                ),
                const SizedBox(height: AppSpacing.md),
                _DocumentRow(
                  title: 'Selfie holding your ID',
                  uploaded: documents.selfieUploaded,
                  onTap: isSaving ? null : () => _pickAndUpload(ref, context, notifier.uploadSelfie),
                ),
                const SizedBox(height: AppSpacing.gutter),
                FilledButton(
                  onPressed: (isSaving || !documents.canSubmit)
                      ? null
                      : () async {
                          await notifier.submit();
                          final state = ref.read(providerDocumentsControllerProvider);
                          if (!context.mounted) return;
                          if (state.hasError) {
                            AppToast.apiError(context, state.error!);
                          } else {
                            AppToast.success(context, 'Submitted for review.');
                          }
                        },
                  child: const Text('Submit for review'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.documents});

  final ProviderDocuments documents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (label, color, message) = switch (documents.verificationStatus) {
      VerificationStatus.approved => (
          'APPROVED',
          StatusColors.positive(context),
          'You\'re verified and visible in search.',
        ),
      VerificationStatus.rejected => (
          'REJECTED',
          StatusColors.negative(context),
          'Your last submission wasn\'t approved - review your documents and submit again.',
        ),
      VerificationStatus.pending => documents.documentsSubmittedAt != null
          ? (
              'PENDING',
              StatusColors.pending(context),
              'An admin is reviewing your documents. This usually takes under 24 hours.',
            )
          : (
              'NOT SUBMITTED',
              StatusColors.pending(context),
              'Upload your documents below, then submit for review.',
            ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadii.field)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(message, style: textTheme.bodyMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.title, required this.uploaded, required this.onTap});

  final String title;
  final bool uploaded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleMedium)),
              if (uploaded)
                Icon(Icons.check_circle, color: StatusColors.positive(context))
              else
                Icon(Icons.upload_outlined, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
