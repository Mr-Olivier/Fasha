import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/secure_network_image.dart';
import '../../auth/presentation/auth_controller.dart';

/// A chat photo, shown inline at bubble size - tapping it opens the same
/// image full-screen with pinch-to-zoom, the same "thumbnail in the
/// conversation, full view on tap" pattern WhatsApp/every other chat app
/// uses rather than only ever showing one fixed size.
class ChatImageAttachment extends StatelessWidget {
  const ChatImageAttachment({super.key, required this.path});

  /// The authenticated path (e.g. "/bookings/$id/messages/$msgId/attachment") -
  /// same convention SecureNetworkImage's own [path] param already uses.
  final String path;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _FullScreenImageViewer(path: path)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: SecureNetworkImage(path: path, width: 220, height: 220, fit: BoxFit.cover),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: SecureNetworkImage(path: path, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// A chat video - shown as a compact placeholder (no network fetch until
/// tapped, unlike the image case, since decoding video just to paint one
/// frame per bubble would mean downloading a chunk of every video in the
/// conversation's history just to scroll past it). Tapping opens a
/// full-screen player that streams the real file with normal play/pause/
/// seek controls.
class ChatVideoAttachment extends StatelessWidget {
  const ChatVideoAttachment({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _FullScreenVideoPlayer(path: path)),
      ),
      child: Container(
        width: 220,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.play_arrow, color: colorScheme.onPrimary, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenVideoPlayer extends ConsumerStatefulWidget {
  const _FullScreenVideoPlayer({required this.path});

  final String path;

  @override
  ConsumerState<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends ConsumerState<_FullScreenVideoPlayer> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = ref.read(authControllerProvider).valueOrNull?.token;
    final uri = Uri.parse('${ApiClient.apiBaseUrl}${widget.path}');
    final controller = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: token != null ? {'Authorization': 'Bearer $token'} : const {},
    );
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller..play());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: _error != null
            ? const Text('Could not load this video.', style: TextStyle(color: Colors.white70))
            : controller == null
                ? const CircularProgressIndicator()
                : AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(controller),
                        _VideoControls(controller: controller),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  const _VideoControls({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(color: Colors.black45),
      child: Row(
        children: [
          IconButton(
            color: Colors.white,
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () => setState(() => isPlaying ? widget.controller.pause() : widget.controller.play()),
          ),
          Expanded(child: VideoProgressIndicator(widget.controller, allowScrubbing: true)),
        ],
      ),
    );
  }
}
