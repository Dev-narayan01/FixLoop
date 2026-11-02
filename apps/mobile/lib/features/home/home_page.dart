import 'package:flutter/material.dart';

import '../../design/widgets.dart';
import '../../preview/photo_picker.dart';
import '../../preview/preview_models.dart';
import '../auth/login_placeholder_page.dart';
import '../feedback/feedback_page.dart';
import '../issues/issue_detail_page.dart';
import '../report/report_flow_page.dart';

class PreviewHomePage extends StatefulWidget {
  const PreviewHomePage({required this.photoPicker, super.key});
  final PreviewPhotoPicker photoPicker;

  @override
  State<PreviewHomePage> createState() => _PreviewHomePageState();
}

class _PreviewHomePageState extends State<PreviewHomePage> {
  final List<PreviewIssue> _issues = sampleIssues();
  bool _searching = false;
  String _query = '';
  int _nextNumber = 1;

  PreviewIssue _previewReport(ReportDraft draft) {
    final issue = PreviewIssue.fromDraft(draft, _nextNumber++);
    setState(() => _issues.insert(0, issue));
    return issue;
  }

  void _openReport() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReportFlowPage(
          photoPicker: widget.photoPicker,
          onPreviewReport: _previewReport,
        ),
      ),
    );
  }

  void _openIssue(PreviewIssue issue) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => IssueDetailPage(
          issue: issue,
          onChanged: () => setState(() {}),
        ),
      ),
    );
  }

  void _openFeedback() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FeedbackPage(photoPicker: widget.photoPicker),
      ),
    );
  }

  void _openProfile() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Sign-in preview'),
                subtitle: const Text('Sign-in is not connected yet'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (_) => const LoginPlaceholderPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded),
                title: const Text('Give feedback'),
                subtitle: const Text('Preview the feedback screen'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openFeedback();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final matching = _issues.where((issue) {
      final q = _query.trim().toLowerCase();
      return q.isEmpty ||
          issue.title.toLowerCase().contains(q) ||
          issue.location.toLowerCase().contains(q);
    }).toList();
    PreviewIssue? featured;
    for (final issue in matching) {
      if (issue.status == PreviewStatus.resolved) {
        featured = issue;
        break;
      }
    }
    final otherIssues = matching.where((issue) => !identical(issue, featured)).toList();

    return FixScreen(
      title: 'Campus home',
      showProfile: false,
      headerActions: <Widget>[
        IconButton(
          tooltip: _searching ? 'Close search' : 'Search example issues',
          icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () => setState(() {
            _searching = !_searching;
            _query = '';
          }),
        ),
        IconButton.filled(
          tooltip: 'Profile options',
          onPressed: _openProfile,
          style: IconButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ],
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_searching) ...<Widget>[
                    TextField(
                      key: const ValueKey<String>('home-search'),
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search example issues',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text('My issues', style: text.displaySmall),
                  const SizedBox(height: 6),
                  Text(
                    'Example issues and reports you preview here',
                    style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  if (featured != null) ...<Widget>[
                    _FeaturedIssue(issue: featured, onOpen: () => _openIssue(featured!)),
                    const SizedBox(height: 28),
                  ],
                  Text('Open and recent', style: text.headlineSmall),
                  const SizedBox(height: 10),
                  if (otherIssues.isEmpty && featured == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No preview issues match your search.'),
                    ),
                  for (final issue in otherIssues)
                    _IssueRow(issue: issue, onTap: () => _openIssue(issue)),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: _openFeedback,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Give feedback'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const ValueKey<String>('start-report'),
                onPressed: _openReport,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Report a problem'),
              ),
            ),
          ),
          NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (index) {
              if (index == 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Updates are not connected in this preview.')),
                );
              } else if (index == 2) {
                _openProfile();
              }
            },
            backgroundColor: colors.surfaceContainer,
            indicatorColor: colors.primaryContainer,
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.update_rounded), label: 'Updates'),
              NavigationDestination(icon: Icon(Icons.account_circle_outlined), label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedIssue extends StatelessWidget {
  const _FeaturedIssue({required this.issue, required this.onOpen});
  final PreviewIssue issue;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MoonArch(
      height: 248,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            const MoonGraphic(phase: MoonPhase.almostFull, size: 84),
            const SizedBox(height: 8),
            Text(
              issue.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(issue.isSample ? 'Example · Ready to check' : 'Preview · Ready to check'),
            const SizedBox(height: 8),
            FilledButton(onPressed: onOpen, child: const Text('Check it')),
          ],
        ),
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue, required this.onTap});
  final PreviewIssue issue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final phase = switch (issue.status) {
      PreviewStatus.inProgress => MoonPhase.half,
      PreviewStatus.resolved => MoonPhase.almostFull,
      PreviewStatus.verified => MoonPhase.full,
      _ => MoonPhase.crescent,
    };
    return Column(
      children: <Widget>[
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: Row(
              children: <Widget>[
                MoonGraphic(phase: phase, size: 42),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(issue.title, style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(issue.location, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        '${issue.isSample ? 'Example' : 'Preview'} · ${issue.status.label}',
                        style: text.bodyMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
