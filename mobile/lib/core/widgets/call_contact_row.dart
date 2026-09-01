import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'app_toast.dart';

/// A tappable "Call {name}" row - shown once a booking is accepted, since
/// that's the only way a customer and provider can actually reach each
/// other right now (there's no in-app chat). Does nothing but show a toast
/// on a device with no phone dialer (e.g. testing in a desktop browser) -
/// canLaunchUrl gates that gracefully instead of throwing.
class CallContactRow extends StatelessWidget {
  const CallContactRow({super.key, required this.name, required this.phone});

  final String name;
  final String phone;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final canLaunch = await canLaunchUrl(uri);
    final launched = canLaunch && await launchUrl(uri);
    if (!launched && context.mounted) {
      AppToast.error(context, 'Could not open the phone dialer on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _call(context),
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_outlined, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Call $name · $phone',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
