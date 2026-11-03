import 'dart:typed_data';

import 'package:flutter/material.dart';

/// The examples in this file never come from or go to the API.
class IssueCategory {
  const IssueCategory(this.name, this.description, this.icon);

  final String name;
  final String description;
  final IconData icon;
}

const previewCategories = <IssueCategory>[
  IssueCategory('Electrical', 'Power & lights', Icons.bolt_outlined),
  IssueCategory('Plumbing', 'Leaks & drains', Icons.water_drop_outlined),
  IssueCategory('Housekeeping', 'Waste & hygiene', Icons.cleaning_services_outlined),
  IssueCategory('Carpentry', 'Doors & latches', Icons.carpenter_outlined),
  IssueCategory('IT & Network', 'Wi-Fi & portals', Icons.wifi_rounded),
  IssueCategory('Hostel & beds', 'Fixtures & desks', Icons.bed_outlined),
  IssueCategory('AC & fans', 'Cooling & vents', Icons.ac_unit_rounded),
  IssueCategory('Campus lawns', 'Pathways & trees', Icons.park_outlined),
];

enum PreviewSeverity {
  low('Low', 'A minor inconvenience'),
  medium('Medium', 'Affects some use'),
  high('High', 'Blocks normal use'),
  critical('Critical', 'Needs urgent attention');

  const PreviewSeverity(this.label, this.description);
  final String label;
  final String description;
}

enum PreviewStatus {
  reported('Received', Icons.inbox_outlined),
  assigned('With the team', Icons.group_outlined),
  inProgress('Being fixed', Icons.build_outlined),
  resolved('Fixed, please check', Icons.task_alt_rounded),
  verified('Closed', Icons.check_circle_outline_rounded),
  reopened('Reopened', Icons.replay_rounded),
  rejected('Not accepted', Icons.block_rounded);

  const PreviewStatus(this.label, this.icon);
  final String label;
  final IconData icon;
}

class PreviewPhoto {
  const PreviewPhoto(this.bytes);
  final Uint8List bytes;
}

class ReportDraft {
  IssueCategory? category;
  String? block;
  String? floor;
  String? room;
  PreviewSeverity severity = PreviewSeverity.medium;
  String description = '';
  final List<PreviewPhoto> photos = <PreviewPhoto>[];

  bool get hasLocation => block != null && floor != null && room != null;
  bool get hasDescription => description.trim().length >= 5;

  String get place => <String>[
        if (block != null) block!,
        if (floor != null) floor!,
        if (room != null) room!,
      ].join(', ');
}

class PreviewIssue {
  PreviewIssue({
    required this.code,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.severity,
    required this.status,
    required this.isSample,
  });

  final String code;
  final String title;
  final String description;
  final String location;
  final IssueCategory category;
  final PreviewSeverity severity;
  final bool isSample;
  PreviewStatus status;
  String? reopenReason;

  factory PreviewIssue.fromDraft(ReportDraft draft, int number) {
    final description = draft.description.trim();
    return PreviewIssue(
      code: 'PREVIEW-${number.toString().padLeft(3, '0')}',
      title: description,
      description: description,
      location: draft.place,
      category: draft.category!,
      severity: draft.severity,
      status: PreviewStatus.reported,
      isSample: false,
    );
  }
}

List<PreviewIssue> sampleIssues() => <PreviewIssue>[
      PreviewIssue(
        code: 'EXAMPLE-000123',
        title: 'Wi-Fi down, hostel',
        description: 'Wi-Fi keeps dropping every few minutes.',
        location: 'Girls Hostel B, Floor 3, Room 304',
        category: previewCategories[4],
        severity: PreviewSeverity.high,
        status: PreviewStatus.resolved,
        isSample: true,
      ),
      PreviewIssue(
        code: 'EXAMPLE-000122',
        title: 'AC not cooling',
        description: 'The room is not cooling.',
        location: 'Block C, Room 204',
        category: previewCategories[6],
        severity: PreviewSeverity.medium,
        status: PreviewStatus.inProgress,
        isSample: true,
      ),
      PreviewIssue(
        code: 'EXAMPLE-000121',
        title: 'Washroom blocked',
        description: 'A drain in the common washroom is blocked.',
        location: 'Block B, Floor 1',
        category: previewCategories[1],
        severity: PreviewSeverity.medium,
        status: PreviewStatus.assigned,
        isSample: true,
      ),
    ];
