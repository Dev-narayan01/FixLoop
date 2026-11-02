import 'dart:convert';

import 'package:fixloop_mobile/main.dart';
import 'package:fixloop_mobile/preview/photo_picker.dart';
import 'package:fixloop_mobile/preview/preview_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePhotoPicker implements PreviewPhotoPicker {
  FakePhotoPicker({this.tooLarge = false});
  final bool tooLarge;
  int calls = 0;

  @override
  Future<PreviewPhoto?> pickPhoto() async {
    calls++;
    if (tooLarge) throw const PhotoTooLargeException();
    return PreviewPhoto(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP43+DwHwAHAAK/K9fH4gAAAABJRU5ErkJggg==',
    ));
  }
}

Future<void> startApp(WidgetTester tester, {PreviewPhotoPicker? picker}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(FixLoopApp(photoPicker: picker ?? FakePhotoPicker()));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String key, String choice) async {
  await tapVisible(tester, find.byKey(ValueKey<String>(key)));
  await tester.tap(find.text(choice).last);
  await tester.pumpAndSettle();
}

Future<void> reachDetails(WidgetTester tester) async {
  await tapVisible(tester, find.text('Report a problem'));
  await tester.enterText(find.byKey(const ValueKey<String>('category-search')), 'wi-fi');
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text('IT & Network'));
  expect(find.text('Where is it?'), findsOneWidget);
  await choose(tester, 'block', 'Girls Hostel B');
  await choose(tester, 'floor-Girls Hostel B', 'Floor 3');
  await choose(tester, 'room-Girls Hostel B-Floor 3', 'Room 304');
  await tapVisible(tester, find.text('Next'));
  expect(find.text('Tell us more'), findsOneWidget);
}

void main() {
  testWidgets('home and preserved sign-in are clearly a preview', (tester) async {
    await startApp(tester);
    expect(find.text('My issues'), findsOneWidget);
    expect(find.text('Preview only · Nothing is sent to Fix Loop'), findsOneWidget);
    expect(find.text('Example · Ready to check'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('Profile options'));
    await tapVisible(tester, find.text('Sign-in preview'));
    expect(find.text('Early preview: sign-in and complaint reporting are not connected yet.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.enabled, isFalse);
    }
  });

  testWidgets('report flow validates, previews a local photo, and never claims to send', (tester) async {
    final picker = FakePhotoPicker();
    await startApp(tester, picker: picker);
    await tapVisible(tester, find.text('Report a problem'));
    expect(find.text('What is wrong?'), findsOneWidget);
    await tapVisible(tester, find.text('More categories'));
    expect(find.text('AC & fans'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey<String>('category-search')), 'wi-fi');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('IT & Network'));

    final nextButton = find.ancestor(of: find.text('Next'), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);
    await choose(tester, 'block', 'Girls Hostel B');
    await choose(tester, 'floor-Girls Hostel B', 'Floor 3');
    await choose(tester, 'room-Girls Hostel B-Floor 3', 'Room 304');
    await tapVisible(tester, find.text('Next'));
    expect(tester.widget<FilledButton>(nextButton).onPressed, isNull);
    await tapVisible(tester, find.text('High'));
    await tester.enterText(find.byKey(const ValueKey<String>('issue-description')), 'Wi-Fi keeps dropping');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey<String>('add-photo')));
    expect(picker.calls, 1);
    expect(find.byTooltip('Remove photo 1'), findsOneWidget);
    await tapVisible(tester, find.text('Next'));

    expect(find.text('Check and send'), findsOneWidget);
    expect(find.text('Girls Hostel B, Floor 3, Room 304'), findsOneWidget);
    expect(find.text('High · Blocks normal use'), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    await tapVisible(tester, find.text('Preview report'));
    expect(find.text('Report previewed'), findsOneWidget);
    expect(find.textContaining('No report was sent.'), findsOneWidget);
    expect(find.text('# PREVIEW-001'), findsOneWidget);
    await tapVisible(tester, find.text('Done'));
    expect(find.text('Wi-Fi keeps dropping'), findsOneWidget);
    expect(find.text('Preview · Received'), findsOneWidget);
  });

  testWidgets('back navigation retains the draft and photo removal is local', (tester) async {
    await startApp(tester);
    await reachDetails(tester);
    await tester.enterText(find.byKey(const ValueKey<String>('issue-description')), 'Example report');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey<String>('add-photo')));
    await tapVisible(tester, find.byTooltip('Remove photo 1'));
    expect(find.byTooltip('Remove photo 1'), findsNothing);
    await tapVisible(tester, find.text('Next'));
    await tapVisible(tester, find.text('Issue'));
    expect(find.text('Example report'), findsOneWidget);
    await tapVisible(tester, find.text('Next'));
    expect(find.text('0 selected'), findsOneWidget);
  });

  testWidgets('a resolved example can be verified without closing a real issue', (tester) async {
    await startApp(tester);
    await tapVisible(tester, find.text('Check it'));
    expect(find.text('Awaiting your confirmation'), findsOneWidget);
    await tapVisible(tester, find.text('Fixed'));
    expect(find.text('Loop closed.'), findsOneWidget);
    expect(find.text('Preview only. No real issue was closed.'), findsOneWidget);
    await tapVisible(tester, find.text('Done'));
    expect(find.text('Example · Closed'), findsOneWidget);
  });

  testWidgets('reopening requires a reason and only changes the example', (tester) async {
    await startApp(tester);
    await tapVisible(tester, find.text('Check it'));
    await tapVisible(tester, find.text('Not fixed'));
    final button = find.ancestor(of: find.text('Preview reopen'), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey<String>('reopen-reason')), 'Still not working');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Preview reopen'));
    expect(find.text('Example · Reopened'), findsOneWidget);
    expect(find.text('Preview updated. No issue was reopened.'), findsOneWidget);
  });

  testWidgets('feedback accepts a local image but explicitly sends nothing', (tester) async {
    final picker = FakePhotoPicker();
    await startApp(tester, picker: picker);
    await tapVisible(tester, find.text('Give feedback'));
    expect(find.text('Tell us what went wrong'), findsOneWidget);
    await tapVisible(tester, find.text('I have an idea'));
    await tapVisible(tester, find.byType(Switch));
    expect(picker.calls, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.enterText(find.byKey(const ValueKey<String>('feedback-message')), 'Example suggestion');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Preview send'));
    expect(find.text('No message or screenshot was sent. Feedback is not connected yet.'), findsOneWidget);
    await tapVisible(tester, find.text('Done'));
    expect(find.text('My issues'), findsOneWidget);
  });

  testWidgets('oversize images are rejected without leaving the preview', (tester) async {
    await startApp(tester, picker: FakePhotoPicker(tooLarge: true));
    await reachDetails(tester);
    await tapVisible(tester, find.byKey(const ValueKey<String>('add-photo')));
    expect(find.text('Choose a photo smaller than 5 MB.'), findsOneWidget);
    expect(find.byTooltip('Remove photo 1'), findsNothing);
  });

  testWidgets('small screens and larger text can scroll without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(FixLoopApp(photoPicker: FakePhotoPicker()));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Report a problem'));
    expect(find.text('What is wrong?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
