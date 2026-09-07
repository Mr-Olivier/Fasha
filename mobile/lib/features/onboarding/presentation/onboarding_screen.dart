import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'onboarding_controller.dart';

class _Slide {
  const _Slide({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;
}

/// A2 in fasha-app-final-ui.html - the 3-dot carousel SplashScreen's own
/// doc comment mentions as "not built yet". Shown once, ever, on a fresh
/// install (see onboardingCompletedProvider); "Skip" and finishing the
/// last slide both lead to the same place, /login.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _slides = [
    _Slide(
      icon: Icons.handyman_outlined,
      title: 'Every trade in Kigali, in one place',
      description:
          'Electricians, plumbers, cleaners, mechanics and tutors - all verified, all rated by real customers.',
    ),
    _Slide(
      icon: Icons.event_available_outlined,
      title: 'Book in a few taps',
      description: 'Pick a service, send your request, and the provider confirms directly with you - no phone tag.',
    ),
    _Slide(
      icon: Icons.chat_bubble_outline,
      title: "Message or call once you're booked",
      description: 'Chat and phone contact unlock the moment your booking is accepted, so you can coordinate directly.',
    ),
  ];

  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await markOnboardingCompleted(ref);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLastSlide = _page == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadii.card),
                            ),
                            child: Icon(slide.icon, size: 96, color: colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.gutter),
                        Text(
                          slide.title,
                          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          slide.description,
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Row(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? colorScheme.primary : colorScheme.outline,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
                    child: Text(isLastSlide ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
