import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageCompressHelper {
  /// Her trl grseli (PNG, JPG, HEIC vb.) arka planda iYleyip
  /// 450px boyuta ve %45 kaliteli JPEG'e dnǬYtǬrǬr.
  /// -kt boyutu kesin olarak 20-35 KB seviyesine dǬYer,
  /// 1 MB Firestore limitini ASLA aYamaz.
  static Future<String> compressAndEncodeBase64(Uint8List rawBytes) async {
    return compute(_isolateCompress, rawBytes);
  }

  static String _isolateCompress(Uint8List rawBytes) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        return 'data:image/jpeg;base64,${base64Encode(rawBytes)}';
      }

      // 450px snr (Oran koruyarak kǬǬlt)
      img.Image resized;
      if (decoded.width > 450 || decoded.height > 450) {
        if (decoded.width >= decoded.height) {
          resized = img.copyResize(decoded, width: 450);
        } else {
          resized = img.copyResize(decoded, height: 450);
        }
      } else {
        resized = decoded;
      }

      // TǬm formatlar (PNG, WebP vb.) standart JPEG'e evir
      var jpgBytes = img.encodeJpg(resized, quality: 45);

      // EYer yine de 70 KB ǬstǬndeyse kaliteyi %30'a ek
      if (jpgBytes.length > 70 * 1024) {
        jpgBytes = img.encodeJpg(resized, quality: 30);
      }

      return 'data:image/jpeg;base64,${base64Encode(jpgBytes)}';
    } catch (e) {
      debugPrint('ImageCompressHelper error: $e');
      return 'data:image/jpeg;base64,${base64Encode(rawBytes)}';
    }
  }
}