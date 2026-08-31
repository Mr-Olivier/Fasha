import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../domain/user_role.dart';
import 'auth_controller.dart';

/// A 2-step wizard (role choice, then details) - matching the design
/// reference, adapted from its 3-step version. We don't know what the
/// design's missing 3rd step would have been (only steps 1 and 2 were
/// actually specified), and our backend only ever needs one register()
/// call at the end, so 2 steps is the honest number for what this form
/// actually does.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

enum _RegisterStep { roleChoice, details }

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  _RegisterStep _step = _RegisterStep.roleChoice;

  // Only CUSTOMER/PROVIDER are offered here - the backend also rejects
  // ADMIN at registration (see InvalidRegistrationRoleException), but
  // there's no reason to let a user pick an option that's guaranteed to
  // fail. Defaulting to CUSTOMER matches the more common signup path, and
  // the design's own mockup shows it pre-selected too.
  UserRole _selectedRole = UserRole.customer;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) return; // the Create account button is already disabled in this case; this is just a safety net

    final phone = _phoneController.text.trim();
    await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          // Rwanda-only app - a fixed "+250" prefix (shown via the field's
          // prefixText below) is simpler and more honest than a full
          // international country-code picker we don't need yet.
          phone: phone.isEmpty ? null : '+250$phone',
          password: _passwordController.text,
          role: _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && !identical(previous?.error, error)) {
        AppToast.apiError(context, error);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (_step == _RegisterStep.details) {
              setState(() => _step = _RegisterStep.roleChoice);
            } else {
              context.go('/login');
            }
          },
        ),
        title: Text(_step == _RegisterStep.roleChoice ? '1/2' : '2/2'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: _step == _RegisterStep.roleChoice ? _buildRoleChoiceStep() : _buildDetailsStep(isLoading),
      ),
    );
  }

  Widget _buildRoleChoiceStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How will you use KaziLink?', style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'You can only pick one - this sets your role.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 24),
        _RoleCard(
          initials: 'CU',
          title: 'I need a service',
          description: 'Find providers, request jobs, track and review them.',
          selected: _selectedRole == UserRole.customer,
          onTap: () => setState(() => _selectedRole = UserRole.customer),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          initials: 'PR',
          title: 'I offer a service',
          description: 'Build a profile, list prices, receive job requests.',
          selected: _selectedRole == UserRole.provider,
          onTap: () => setState(() => _selectedRole = UserRole.provider),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Text(
            'Provider accounts are reviewed by an admin before they appear in search - usually within 24 hours.',
            style: textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _step = _RegisterStep.details),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildDetailsStep(bool isLoading) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your details', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) => Validators.required(value, fieldName: 'Name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)', prefixText: '+250 '),
            validator: Validators.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'Must be at least 8 characters',
              suffixIcon: TextButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Text(_obscurePassword ? 'Show' : 'Hide'),
              ),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('I agree to the Terms of Service and Privacy Policy.'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (isLoading || !_agreedToTerms) ? null : _submit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create account'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: isLoading ? null : () => context.go('/login'),
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.initials,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String initials;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: selected ? colorScheme.primary : colorScheme.outline, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: selected ? colorScheme.primary : colorScheme.secondaryContainer,
              foregroundColor: selected ? Colors.white : colorScheme.onSecondaryContainer,
              child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  Text(description, style: textTheme.bodySmall),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}
