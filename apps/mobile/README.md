# Flutter design preview

The supplied Stitch designs are implemented as a **local-only preview**: campus
home, category, location, details/photos, review, report confirmation, resolved
issue detail, loop closed, and feedback. It uses the included open-licensed
Bricolage Grotesque and Atkinson Hyperlegible Next fonts (licenses are in
`assets/fonts/`) and follows the system light/dark setting.

The issue list and locations are examples. Form state and example status changes
are held in memory and reset when the app exits. The photo picker can select up
to three local images (5 MB each); the feedback screen can select a screenshot.
No image, report or feedback is uploaded or sent. The picker or operating system
may temporarily cache selected files. Please use synthetic text and images only.
Private reporting, sign-in and real notifications are not implemented.

There is intentionally **no API client yet**: real submission requires the
Java API's authentication, authorization, complaint/feedback endpoints,
storage and privacy safeguards first. When connected, Flutter should call that
API over HTTP, never connect to Postgres or hold Supabase database credentials.

The target is Flutter **3.41.9** / Dart **3.11.5**. From this folder:

```sh
flutter create --no-pub --platforms=android,web --project-name fixloop_mobile --org com.fixloop .
flutter pub get
flutter analyze
flutter test
flutter run -d chrome       # or select an Android device with flutter devices
```

For web without Chrome detected by Flutter, use:

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8081
```

Open the printed URL in a browser on the same computer. Android photo picking
uses the system picker; no camera capture is implemented. Web photo selection
uses the browser's file picker.

The Android and web host projects are intentionally not committed yet: the
first command generates standard host files using the installed Flutter SDK. It
repairs missing files and, without `--overwrite`, does not replace our Dart
source, pubspec or tests. Review and commit generated host files after agreeing
on the Android application ID. Do not commit `local.properties`, signing keys
or credentials.
