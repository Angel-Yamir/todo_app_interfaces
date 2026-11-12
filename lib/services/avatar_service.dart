import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Picks an image already downscaled to 256px / 70% quality (~20-40 KB) and
/// returns it base64-encoded so it can live in a Firestore document.
class AvatarService {
  Future<String?> pickAvatarBase64() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 70,
    );
    if (picked == null) return null;
    final Uint8List bytes = await picked.readAsBytes();
    return base64Encode(bytes);
  }
}
