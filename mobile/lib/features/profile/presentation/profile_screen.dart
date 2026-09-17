import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_controller.dart';
import 'user_profile_controller.dart';

/// The account tab - who's logged in, editing name/phone, changing
/// password, uploading an avatar, and (still) where "Log out" lives.
///
/// Not to be confused with ProviderProfileScreen (features/providers) -
/// that's the provider's public BUSINESS profile (name, description,
/// services); this is the logged-in user's own ACCOUNT screen, which every
/// role has.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAndUploadAvatar(WidgetRef ref) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) return; // user cancelled the picker
    await ref.read(userProfileControllerProvider.notifier).uploadAvatar(image);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    // Watched (not just read) so build() actually runs and fetches
    // GET /api/users/me the first time this screen opens - see
    // UserProfileController's doc comment for why that matters (AuthUser
    // from login/register doesn't carry phone/profileImageUrl yet).
    final profileState = ref.watch(userProfileControllerProvider);
    final isUploadingAvatar = profileState.isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen(userProfileControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: BrandedAppBar(
        title: user?.role == UserRole.provider ? 'Fasha Pro' : 'Fasha',
        subtitle: 'Profile',
      ),
      body: user == null
          ? const Center(child: Text('No user logged in.'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          _Avatar(user: user, colorScheme: colorScheme),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: isUploadingAvatar ? null : () => _pickAndUploadAvatar(ref),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: colorScheme.secondary,
                                child: isUploadingAvatar
                                    ? SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.onSecondary,
                                        ),
                                      )
                                    : Icon(Icons.camera_alt, size: 16, color: colorScheme.onSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(user.name, style: textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(user.email, style: textTheme.bodyMedium),
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(user.phone!, style: textTheme.bodySmall),
                      ],
                      const SizedBox(height: 8),
                      Chip(label: Text(_roleLabel(user))),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.gutter),
                const _AppearanceCard(),
                const SizedBox(height: AppSpacing.md),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Edit profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/profile/edit'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/profile/change-password'),
                      ),
                    ],
                  ),
                ),
                if (user.role == UserRole.provider) ...[
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.storefront_outlined),
                          title: const Text('Business profile'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/provider-profile'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.verified_outlined),
                          title: const Text('Verification'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/get-verified'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(Icons.logout, color: colorScheme.error),
                    title: Text('Log out', style: TextStyle(color: colorScheme.error)),
                    onTap: () => ref.read(authControllerProvider.notifier).logout(),
                  ),
                ),
              ],
            ),
    );
  }

  String _roleLabel(AuthUser user) => '${user.role.name[0].toUpperCase()}${user.role.name.substring(1)}';
}

/// "Appearance: Light / Dark / System" - see F2 in fasha-app-final-ui.html.
/// Reads/writes ThemeModeController, which persists the choice so it
/// survives an app restart instead of resetting to System every time.
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: {themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  ref.read(themeModeControllerProvider.notifier).setThemeMode(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.colorScheme});

  final AuthUser user;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.profileImageUrl;
    return CircleAvatar(
      radius: 48,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      // See ApiClient.resolveMediaUrl's doc comment for why this isn't a
      // plain string concatenation.
      backgroundImage: imageUrl != null ? NetworkImage(ApiClient.resolveMediaUrl(imageUrl)) : null,
      child: imageUrl == null
          ? Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}
