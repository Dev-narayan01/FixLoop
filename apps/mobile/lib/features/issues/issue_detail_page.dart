import 'package:flutter/material.dart';

import '../../design/widgets.dart';
import '../../preview/preview_models.dart';
import 'loop_closed_page.dart';

class IssueDetailPage extends StatefulWidget {
  const IssueDetailPage({required this.issue, required this.onChanged, super.key});
  final PreviewIssue issue;
  final VoidCallback onChanged;

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  void _previewFixed() {
    setState(() => widget.issue.status = PreviewStatus.verified);
    widget.onChanged();
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => LoopClosedPage(code: widget.issue.code)),
    );
  }

  Future<void> _previewNotFixed() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReopenDialog(),
    );
    if (!mounted || reason == null) return;
    setState(() {
      widget.issue.status = PreviewStatus.reopened;
      widget.issue.reopenReason = reason;
    });
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview updated. No issue was reopened.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final canCheck = issue.status == PreviewStatus.resolved;
    final phase = switch (issue.status) {
      PreviewStatus.verified => MoonPhase.full,
      PreviewStatus.resolved => MoonPhase.almostFull,
      PreviewStatus.inProgress => MoonPhase.half,
      _ => MoonPhase.crescent,
    };
    return FixScreen(
      title: 'Issue detail',
      onBack: () => Navigator.of(context).pop(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('# ${issue.code}', style: text.bodyMedium),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: Align(alignment: Alignment.centerRight, child: StatusBadge(status: issue.status))),
              ],
            ),
            const SizedBox(height: 20),
            MoonArch(
              height: 225,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  MoonGraphic(phase: phase, size: 140, orbit: true),
                  const SizedBox(height: 6),
                  Text(
                    canCheck ? 'Awaiting your confirmation' : issue.status.label,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(color: colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(issue.status.label, style: text.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              issue.isSample ? 'Example issue · not a real report' : 'Preview issue · not submitted',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: colors.surfaceContainer,
                    child: Icon(issue.category.icon, color: colors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Issue', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(issue.title, style: text.titleMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 16),
              title: const Text('Details'),
              children: <Widget>[
                _DetailLine(label: 'Category', value: issue.category.name),
                _DetailLine(label: 'Location', value: issue.location),
                _DetailLine(label: 'Severity', value: issue.severity.label),
                _DetailLine(label: 'Description', value: issue.description),
                if (issue.reopenReason != null) _DetailLine(label: 'Reopen note', value: issue.reopenReason!),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 16),
              title: const Text('History'),
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    issue.isSample
                        ? 'Example timeline only. No real history is connected.'
                        : 'This report exists only in the current preview.',
                    style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            if (canCheck) ...<Widget>[
              const SizedBox(height: 26),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previewNotFixed,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Not fixed'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _previewFixed,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Fixed'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'These buttons update the example only.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 92, child: Text(label)),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _ReopenDialog extends StatefulWidget {
  const _ReopenDialog();

  @override
  State<_ReopenDialog> createState() => _ReopenDialogState();
}

class _ReopenDialogState extends State<_ReopenDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What still needs fixing?'),
      content: TextField(
        key: const ValueKey<String>('reopen-reason'),
        controller: _reason,
        minLines: 2,
        maxLines: 4,
        maxLength: 500,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(hintText: 'Add a note for this preview'),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _reason.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _reason.text.trim()),
          child: const Text('Preview reopen'),
        ),
      ],
    );
  }
}
