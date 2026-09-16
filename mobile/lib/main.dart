import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/chat/data/pending_attachment_store.dart';
import 'features/chat/presentation/chat_screen.dart';

void main() {
  runApp(
    // ProviderScope stores the state of every Riverpod provider in the app.
    // It must wrap the app exactly once, at the very root - every feature's
    // providers (auth, bookings, ...) will read/write through this scope.
    const ProviderScope(child: FashaApp()),
  );
}

/// ConsumerStatefulWidget (not a plain ConsumerWidget) because startup also
/// needs to run pending-attachment recovery exactly once - see initState
/// and _recoverPendingAttachment below.
class FashaApp extends ConsumerStatefulWidget {
  const FashaApp({super.key});

  @override
  ConsumerState<FashaApp> createState() => _FashaAppState();
}

class _FashaAppState extends ConsumerState<FashaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_recoverPendingAttachment()));
  }

  /// Camera-based chat attachments can outlive the Android process that
  /// started them (see PendingAttachmentStore's doc comment) - when that
  /// happens, the app cold-starts back at the splash screen with no memory
  /// of which chat was open, same as any other fresh launch. This runs
  /// once per launch, and if PendingAttachmentStore has a marker AND
  /// Android actually has a photo/video waiting (retrieveLostData is only
  /// non-empty right after that exact kind of restart - a normal cold
  /// start gets nothing here), it jumps straight to that chat and hands it
  /// the recovered file, instead of leaving the user to notice a photo was
  /// taken and go find that conversation themselves.
  Future<void> _recoverPendingAttachment() async {
    final pending = await PendingAttachmentStore.read();
    if (pending == null) return;

    // GoRouter's redirect (see appRouterProvider) sends anything but
    // /splash back to /splash while AuthController is still restoring the
    // session from secure storage - wait that out first, otherwise the
    // push below would just get bounced.
    while (mounted && ref.read(authControllerProvider).isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted || ref.read(authControllerProvider).valueOrNull == null) {
      await PendingAttachmentStore.clear();
      return;
    }

    final response = await ImagePicker().retrieveLostData();
    await PendingAttachmentStore.clear();
    if (response.isEmpty || response.file == null || !mounted) return;

    ref.read(appRouterProvider).push(
      '/chat',
      extra: ChatScreenArgs(
        bookingId: pending.bookingId,
        otherPartyName: pending.otherPartyName,
        pendingAttachment: (file: response.file!, isVideo: response.type == RetrieveType.video),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: 'FASHA APP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Defaults to following the phone's own setting, but the user can
      // override it from Profile > Appearance - see ThemeModeController.
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
