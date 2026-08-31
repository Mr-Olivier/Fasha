import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_user.dart';
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
        final message = error is ApiException ? error.message : 'Something went wrong.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
      foregroundColor: Colors.white,
      // StaticResourceConfig serves this at the backend's plain host, not
      // under "/api" - see ApiClient.mediaBaseUrl's doc comment.
      backgroundImage: imageUrl != null ? NetworkImage('${ApiClient.mediaBaseUrl}$imageUrl') : null,
      child: imageUrl == null
          ? Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}
