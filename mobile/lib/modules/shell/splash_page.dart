import 'package:flutter/material.dart';
import 'package:itc_events/app/theme/app_theme.dart';
import 'package:itc_events/modules/shell/main_shell.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  void _browseEvents(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/app_logo_transparent_white.png',
                  height: 126,
                ),
                const SizedBox(height: 24),
                // Text(
                //   'GoITC',
                //   textAlign: TextAlign.center,
                //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                //     color: Colors.white,
                //     fontWeight: FontWeight.w700,
                //     height: 1.2,
                //   ),
                // ),
                const SizedBox(height: 8),
                Text(
                  'Book tickets for ITC campus events.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: const [
                    _TagChip(label: 'No payment'),
                    _TagChip(label: 'Instant QR'),
                    _TagChip(label: 'ITC only'),
                  ],
                ),
                const Spacer(flex: 3),
                FilledButton(
                  onPressed: () => _browseEvents(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Browse events'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _browseEvents(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('I already have an account'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
