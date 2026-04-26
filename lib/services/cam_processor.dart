import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

class CamProcessor {
  static const MethodChannel _channel = MethodChannel('bone_cam_processor');

  static const Set<String> _availableParts = {'elbow', 'finger', 'forearm', 'wrist'};

  /// Returns a jet-colormap heatmap blended onto the original image as PNG bytes,
  /// or null if no CAM model exists for [bonePart] or inference fails.
  Future<Uint8List?> generateCAM(File imageFile, String bonePart) async {
    if (!_availableParts.contains(bonePart)) {
      log('[CAM] No model for bone part: $bonePart');
      return null;
    }
    try {
      final result = await _channel.invokeMethod<Uint8List>('generateCAM', {
        'imagePath': imageFile.path,
        'bonePart': bonePart,
      });
      log('[CAM] Received ${result?.length ?? 0} bytes for $bonePart');
      return result;
    } on PlatformException catch (e) {
      log('[CAM] PlatformException: ${e.code} — ${e.message}\n${e.details}');
      return null;
    } catch (e) {
      log('[CAM] Unexpected error: $e');
      return null;
    }
  }
}
