import 'package:image_picker/image_picker.dart';

import 'preview_models.dart';

/// Isolated behind an interface so preview flows can be tested without a device.
abstract interface class PreviewPhotoPicker {
  Future<PreviewPhoto?> pickPhoto();
}

class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException();
}

class DevicePhotoPicker implements PreviewPhotoPicker {
  const DevicePhotoPicker();

  static const maxBytes = 5 * 1024 * 1024;

  @override
  Future<PreviewPhoto?> pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    if (await file.length() > maxBytes) throw const PhotoTooLargeException();
    return PreviewPhoto(await file.readAsBytes());
  }
}
