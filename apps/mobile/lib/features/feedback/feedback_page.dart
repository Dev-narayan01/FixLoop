import 'package:flutter/material.dart';

import '../../design/widgets.dart';
import '../../preview/photo_picker.dart';
import '../../preview/preview_models.dart';

enum _FeedbackKind {
  broken('Something broke', Icons.build_outlined),
  idea('I have an idea', Icons.lightbulb_outline_rounded),
  question('I have a question', Icons.help_outline_rounded);

  const _FeedbackKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({required this.photoPicker, super.key});
  final PreviewPhotoPicker photoPicker;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _message = TextEditingController();
  _FeedbackKind _kind = _FeedbackKind.broken;
  PreviewPhoto? _screenshot;
  bool _picking = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _selectScreenshot(bool include) async {
    if (!include) {
      setState(() => _screenshot = null);
      return;
    }
    setState(() => _picking = true);
    try {
      final photo = await widget.photoPicker.pickPhoto();
      if (mounted && photo != null) setState(() => _screenshot = photo);
    } on PhotoTooLargeException {
      if (mounted) _showMessage('Choose an image smaller than 5 MB.');
    } catch (_) {
      if (mounted) _showMessage('Could not open photos on this device.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _previewSend() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Feedback preview'),
        content: const Text('No message or screenshot was sent. Feedback is not connected yet.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Keep editing')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return FixScreen(
      title: 'Feedback',
      onBack: () => Navigator.of(context).pop(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Tell us what went wrong', style: text.headlineLarge),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final kind in _FeedbackKind.values)
                  ChoiceChip(
                    avatar: Icon(kind.icon, size: 18, color: _kind == kind ? colors.onPrimary : colors.onSurface),
                    label: Text(kind.label),
                    selected: _kind == kind,
                    selectedColor: colors.primary,
                    backgroundColor: colors.surfaceContainerHigh,
                    showCheckmark: false,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: _kind == kind ? colors.onPrimary : colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            TextField(
              key: const ValueKey<String>('feedback-message'),
              controller: _message,
              minLines: 5,
              maxLines: 8,
              maxLength: 2000,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'What happened?'),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: <Widget>[
                  if (_screenshot == null)
                    CircleAvatar(
                      backgroundColor: colors.surfaceContainer,
                      child: Icon(Icons.image_outlined, color: colors.primary),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _screenshot!.bytes,
                        width: 42,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(width: 42, height: 52, child: Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Include screenshot', style: text.titleMedium),
                        const SizedBox(height: 3),
                        Text(
                          'Choose an image for preview only.',
                          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Include screenshot',
                    child: Switch(
                      value: _screenshot != null,
                      onChanged: _picking ? null : _selectScreenshot,
                      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) =>
                          states.contains(WidgetState.selected) ? const Icon(Icons.check_rounded) : null),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            PrimaryAction(
              label: 'Preview send',
              icon: Icons.send_outlined,
              onPressed: _message.text.trim().length < 5 ? null : _previewSend,
            ),
            const SizedBox(height: 12),
            Text(
              'Please use example text, not personal or sensitive information.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
