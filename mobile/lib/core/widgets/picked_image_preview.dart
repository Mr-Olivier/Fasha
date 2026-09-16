import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Renders a just-picked, still-local image (from ImagePicker, before it's
/// uploaded anywhere) - NOT `Image.file(File(xfile.path))`, which throws on
/// Flutter Web ("Image.file is not supported on Flutter Web" - dart:io's
/// File doesn't exist there, only on native platforms; an XFile's `path` on
/// web is a blob: URL, not a real filesystem path anyway). Reading the
/// bytes through XFile.readAsBytes() and painting them with Image.memory
/// works identically on every platform this app targets, so screens never
/// need their own web/native split just to preview a picked photo.
class PickedImagePreview extends StatelessWidget {
  const PickedImagePreview({super.key, required this.file, this.width, this.height, this.fit = BoxFit.cover});

  final XFile file;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return Image.memory(snapshot.data!, width: width, height: height, fit: fit);
      },
    );
  }
}
