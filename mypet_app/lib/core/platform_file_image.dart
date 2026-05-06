// Cross-platform file image helpers.
// On web: uses NetworkImage (image_picker returns blob URLs on web).
// On mobile/desktop: uses FileImage / Image.file from dart:io.
export 'platform_file_image_stub.dart'
    if (dart.library.io) 'platform_file_image_io.dart';
