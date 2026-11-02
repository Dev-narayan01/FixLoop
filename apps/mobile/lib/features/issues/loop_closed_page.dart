import 'package:flutter/material.dart';

import '../../design/widgets.dart';

class LoopClosedPage extends StatelessWidget {
  const LoopClosedPage({required this.code, super.key});
  final String code;

  void _done(BuildContext context) => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return FixScreen(
      title: 'Issue detail',
      onBack: () => _done(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const MoonArch(
              height: 250,
              child: Center(child: MoonGraphic(phase: MoonPhase.full, size: 168)),
            ),
            const SizedBox(height: 32),
            Text('Loop closed.', style: text.displaySmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Preview only. No real issue was closed.',
              style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('# $code', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 72),
            PrimaryAction(label: 'Done', onPressed: () => _done(context)),
          ],
        ),
      ),
    );
  }
}
