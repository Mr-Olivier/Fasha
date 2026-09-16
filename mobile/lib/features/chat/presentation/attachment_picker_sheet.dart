import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/picked_image_preview.dart';
import '../data/pending_attachment_store.dart';

/// The longest a customer can record when showing a technician an issue -
/// long enough to walk around a problem (a leak, a tripped breaker, a
/// noisy appliance) without the upload becoming unreasonably large on a
/// mobile connection.
const chatVideoMaxDuration = Duration(minutes: 3);

/// What was picked, and which kind it is - AttachmentPickerSheet knows this
/// from which button was tapped (pickImage vs. pickVideo), which is
/// cheaper and more reliable than the caller re-deriving it from the
/// file's extension afterwards.
typedef PickedAttachment = ({XFile file, bool isVideo});

/// The "+" menu next to ChatScreen's text field - photo or video, from the
/// gallery or freshly captured, the same four options WhatsApp's own
/// attach menu offers for exactly this case (showing, not just describing,
/// what's wrong). Returns the picked file, or null if dismissed without
/// picking anything.
class AttachmentPickerSheet {
  AttachmentPickerSheet._();

  static Future<PickedAttachment?> show(
    BuildContext context, {
    required String bookingId,
    required String otherPartyName,
  }) {
    return showModalBottomSheet<PickedAttachment?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AttachmentPickerSheet(bookingId: bookingId, otherPartyName: otherPartyName),
    );
  }
}

class _AttachmentPickerSheet extends StatelessWidget {
  const _AttachmentPickerSheet({required this.bookingId, required this.otherPartyName});

  final String bookingId;
  final String otherPartyName;

  Future<void> _pick(
    BuildContext context,
    Future<XFile?> Function() picker, {
    required bool isVideo,
    required bool isCameraSource,
  }) async {
    // Only the camera hands control to a separate system app that can get
    // this app's process killed for memory - see PendingAttachmentStore's
    // doc comment. Picking from the gallery never leaves this app, so
    // there's nothing to remember for it.
    if (isCameraSource) await PendingAttachmentStore.save(bookingId: bookingId, otherPartyName: otherPartyName);
    final file = await picker();
    if (isCameraSource) await PendingAttachmentStore.clear();
    if (context.mounted) Navigator.of(context).pop(file == null ? null : (file: file, isVideo: isVideo));
  }

  @override
  Widget build(BuildContext context) {
    final picker = ImagePicker();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Share with the other party', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _OptionTile(
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              onTap: () => _pick(
                context,
                () => picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85),
                isVideo: false,
                isCameraSource: true,
              ),
            ),
            _OptionTile(
              icon: Icons.image_outlined,
              label: 'Choose a photo',
              onTap: () => _pick(
                context,
                () => picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85),
                isVideo: false,
                isCameraSource: false,
              ),
            ),
            _OptionTile(
              icon: Icons.videocam_outlined,
              label: 'Record a video (up to ${chatVideoMaxDuration.inMinutes} min)',
              onTap: () => _pick(
                context,
                () => picker.pickVideo(source: ImageSource.camera, maxDuration: chatVideoMaxDuration),
                isVideo: true,
                isCameraSource: true,
              ),
            ),
            _OptionTile(
              icon: Icons.video_library_outlined,
              label: 'Choose a video',
              onTap: () => _pick(
                context,
                () => picker.pickVideo(source: ImageSource.gallery, maxDuration: chatVideoMaxDuration),
                isVideo: true,
                isCameraSource: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(label),
      onTap: onTap,
    );
  }
}

/// Shown after a file's picked - a small preview, an optional caption, and
/// Send/Cancel, the same "confirm before it goes" step WhatsApp puts
/// between picking media and it actually landing in the conversation.
/// Returns the caption text (possibly empty) if "Send" was tapped, or null
/// if dismissed - the caller tells those apart with `result == null`, not
/// by the string being empty.
class AttachmentPreviewSheet {
  AttachmentPreviewSheet._();

  static Future<String?> show(BuildContext context, {required XFile file, required bool isVideo}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AttachmentPreviewSheet(file: file, isVideo: isVideo),
    );
  }
}

class _AttachmentPreviewSheet extends StatefulWidget {
  const _AttachmentPreviewSheet({required this.file, required this.isVideo});

  final XFile file;
  final bool isVideo;

  @override
  State<_AttachmentPreviewSheet> createState() => _AttachmentPreviewSheetState();
}

class _AttachmentPreviewSheetState extends State<_AttachmentPreviewSheet> {
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          top: AppSpacing.gutter,
          bottom: AppSpacing.gutter + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: widget.isVideo
                  ? Container(
                      height: 180,
                      color: colorScheme.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam, size: 40, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: AppSpacing.xs),
                          Text(widget.file.name, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )
                  : PickedImagePreview(file: widget.file, height: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _captionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Add a caption (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_captionController.text),
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
