import 'package:flutter/material.dart';

import '../../design/widgets.dart';
import '../../preview/photo_picker.dart';
import '../../preview/preview_models.dart';

class ReportFlowPage extends StatefulWidget {
  const ReportFlowPage({
    required this.photoPicker,
    required this.onPreviewReport,
    super.key,
  });

  final PreviewPhotoPicker photoPicker;
  final PreviewIssue Function(ReportDraft draft) onPreviewReport;

  @override
  State<ReportFlowPage> createState() => _ReportFlowPageState();
}

class _ReportFlowPageState extends State<ReportFlowPage> {
  final ReportDraft _draft = ReportDraft();
  final TextEditingController _search = TextEditingController();
  final TextEditingController _description = TextEditingController();
  int _step = 0;
  bool _showMore = false;
  bool _pickingPhoto = false;
  PreviewIssue? _previewedIssue;

  static const _blocks = <String>['Girls Hostel B', 'Boys Hostel A', 'Academic Block', 'Library'];
  static const _floors = <String>['Ground floor', 'Floor 1', 'Floor 2', 'Floor 3', 'Floor 4'];
  static const _rooms = <String>['Room 301', 'Room 302', 'Room 304', 'Common area'];

  @override
  void dispose() {
    _search.dispose();
    _description.dispose();
    super.dispose();
  }

  void _back() {
    if (_step == 0 || _step == 4) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  void _next() {
    if (_step == 1 && _draft.hasLocation || _step == 2 && _draft.hasDescription) {
      setState(() => _step++);
    }
  }

  void _previewSubmit() {
    if (_draft.category == null || !_draft.hasLocation || !_draft.hasDescription) return;
    final issue = widget.onPreviewReport(_draft);
    setState(() {
      _previewedIssue = issue;
      _step = 4;
    });
  }

  Future<void> _pickPhoto() async {
    if (_pickingPhoto || _draft.photos.length >= 3) return;
    setState(() => _pickingPhoto = true);
    try {
      final photo = await widget.photoPicker.pickPhoto();
      if (!mounted) return;
      if (photo != null) setState(() => _draft.photos.add(photo));
    } on PhotoTooLargeException {
      if (mounted) _showMessage('Choose a photo smaller than 5 MB.');
    } catch (_) {
      if (mounted) _showMessage('Could not open photos on this device.');
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _step == 4;
    return PopScope<Object?>(
      canPop: _step == 0 || isSuccess,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: FixScreen(
        title: 'Report issue',
        onBack: _back,
        child: isSuccess
            ? _ReportPreviewSuccess(issue: _previewedIssue!, onDone: _back)
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: StepProgress(step: _step + 1),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey<int>(_step),
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                      child: switch (_step) {
                        0 => _categoryStep(),
                        1 => _locationStep(),
                        2 => _detailsStep(),
                        _ => _reviewStep(),
                      },
                    ),
                  ),
                  if (_step > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: _bottomAction(),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _categoryStep() {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final query = _search.text.trim().toLowerCase();
    final visible = previewCategories.where((category) {
      if (query.isNotEmpty) {
        return category.name.toLowerCase().contains(query) ||
            category.description.toLowerCase().contains(query);
      }
      return _showMore || previewCategories.indexOf(category) < 6;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('What is wrong?', style: text.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Select an issue area to start your campus repair loop.',
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey<String>('category-search'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search categories',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No categories found. Try a different search.'),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 310 ? 1 : 2;
              final itemWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
              final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final itemHeight = 76.0 * textScale.clamp(1.0, 2.5);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final category in visible)
                    SizedBox(
                      width: itemWidth,
                      height: itemHeight,
                      child: _CategoryTile(
                        category: category,
                        onTap: () => setState(() {
                          _draft.category = category;
                          _step = 1;
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
        if (query.isEmpty) ...<Widget>[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => setState(() => _showMore = !_showMore),
            icon: Icon(_showMore ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label: Text(_showMore ? 'Fewer categories' : 'More categories'),
          ),
        ],
        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 12),
        Material(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.surfaceContainer,
              child: Icon(Icons.lock_outline_rounded, color: colors.primary),
            ),
            title: const Text('Private reports'),
            subtitle: const Text('Not available in this preview'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showMessage('Private reporting is not implemented yet.'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Use examples only; do not enter real or sensitive information.',
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _locationStep() {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Where is it?', style: text.displaySmall),
        const SizedBox(height: 8),
        Text('Tell us the exact spot on campus.', style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 28),
        _locationDropdown(
          label: 'Campus block',
          icon: Icons.apartment_rounded,
          value: _draft.block,
          choices: _blocks,
          stateKey: 'block',
          onChanged: (value) => setState(() {
            _draft.block = value;
            _draft.floor = null;
            _draft.room = null;
          }),
        ),
        const SizedBox(height: 18),
        _locationDropdown(
          label: 'Floor level',
          icon: Icons.layers_outlined,
          value: _draft.floor,
          choices: _floors,
          stateKey: 'floor-${_draft.block}',
          onChanged: _draft.block == null
              ? null
              : (value) => setState(() {
                    _draft.floor = value;
                    _draft.room = null;
                  }),
        ),
        const SizedBox(height: 18),
        _locationDropdown(
          label: 'Specific room or zone',
          icon: Icons.meeting_room_outlined,
          value: _draft.room,
          choices: _rooms,
          stateKey: 'room-${_draft.block}-${_draft.floor}',
          onChanged: _draft.floor == null ? null : (value) => setState(() => _draft.room = value),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline_rounded, color: colors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'These are sample locations, not live campus data.',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _locationDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> choices,
    required String stateKey,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(stateKey),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(prefixIcon: Icon(icon)),
          hint: Text('Select ${label.toLowerCase()}'),
          items: choices.map((choice) => DropdownMenuItem<String>(value: choice, child: Text(choice))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _detailsStep() {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Tell us more', style: text.displaySmall),
        const SizedBox(height: 22),
        Text('Severity', style: text.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final severity in PreviewSeverity.values)
              ChoiceChip(
                label: Text(severity.label),
                selected: _draft.severity == severity,
                showCheckmark: false,
                selectedColor: colors.primary,
                backgroundColor: colors.surfaceContainerHigh,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: _draft.severity == severity ? colors.onPrimary : colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => setState(() => _draft.severity = severity),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_draft.severity.description, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey<String>('issue-description'),
          controller: _description,
          minLines: 4,
          maxLines: 6,
          maxLength: 2000,
          onChanged: (value) => setState(() => _draft.description = value),
          decoration: const InputDecoration(
            labelText: 'What happened?',
            hintText: 'Describe the example issue',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        Text('Photos (optional)', style: text.titleMedium),
        const SizedBox(height: 5),
        Text(
          'Up to 3 images, 5 MB each. Selected for preview only.',
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (var index = 0; index < _draft.photos.length; index++)
              _PhotoThumbnail(
                photo: _draft.photos[index],
                onRemove: () => setState(() => _draft.photos.removeAt(index)),
                index: index,
              ),
            if (_draft.photos.length < 3)
              Tooltip(
                message: 'Add photo',
                child: Material(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    key: const ValueKey<String>('add-photo'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickingPhoto ? null : _pickPhoto,
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.add_a_photo_outlined, color: colors.primary),
                          const SizedBox(height: 6),
                          Text('Add photo', style: text.bodyMedium?.copyWith(color: colors.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _reviewStep() {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Check and send', style: text.displaySmall),
        const SizedBox(height: 22),
        _ReviewRow(label: 'Category', value: _draft.category!.name, onEdit: () => setState(() => _step = 0)),
        _ReviewRow(label: 'Place', value: _draft.place, onEdit: () => setState(() => _step = 1)),
        _ReviewRow(
          label: 'Severity',
          value: '${_draft.severity.label} · ${_draft.severity.description}',
          onEdit: () => setState(() => _step = 2),
        ),
        _ReviewRow(label: 'Issue', value: _draft.description.trim(), onEdit: () => setState(() => _step = 2)),
        _ReviewRow(
          label: 'Photos',
          value: '${_draft.photos.length} selected',
          onEdit: () => setState(() => _step = 2),
        ),
        if (_draft.photos.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final photo in _draft.photos)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    photo.bytes,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(width: 58, height: 58, child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.lock_outline_rounded, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Privacy and submission are not implemented yet. Do not enter real information.',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bottomAction() => switch (_step) {
        1 => PrimaryAction(label: 'Next', icon: Icons.arrow_forward_rounded, onPressed: _draft.hasLocation ? _next : null),
        2 => PrimaryAction(label: 'Next', icon: Icons.arrow_forward_rounded, onPressed: _draft.hasDescription ? _next : null),
        _ => PrimaryAction(label: 'Preview report', icon: Icons.arrow_forward_rounded, onPressed: _previewSubmit),
      };
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});
  final IssueCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: colors.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.surfaceContainerLowest,
                child: Icon(category.icon, color: colors.primary, size: 21),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      category.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo, required this.onRemove, required this.index});
  final PreviewPhoto photo;
  final VoidCallback onRemove;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              photo.bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Colors.black12,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton.filledTonal(
              tooltip: 'Remove photo ${index + 1}',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value, required this.onEdit});
  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 76, child: Text(label, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant))),
                const SizedBox(width: 8),
                Expanded(child: Text(value, textAlign: TextAlign.right, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700))),
                const SizedBox(width: 6),
                Icon(Icons.edit_outlined, size: 18, color: colors.primary),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _ReportPreviewSuccess extends StatelessWidget {
  const _ReportPreviewSuccess({required this.issue, required this.onDone});
  final PreviewIssue issue;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MoonArch(
            height: 236,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const MoonGraphic(phase: MoonPhase.crescent, size: 150, orbit: true),
                StatusBadge(status: issue.status),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text('Report previewed', style: text.displaySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('# ${issue.code}', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No report was sent. This preview clears when you close the app.',
            style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          PrimaryAction(label: 'Done', onPressed: onDone),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onDone,
            icon: const Icon(Icons.visibility_outlined, size: 19),
            label: const Text('View preview issues'),
          ),
        ],
      ),
    );
  }
}
