import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget? errorWidget;

  static final Map<String, Uint8List> _base64Cache = {};

  const AppImage({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final fallbackError = Container(
      height: height,
      width: width,
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Icon(Icons.broken_image, size: 28, color: theme.colorScheme.primary),
    );

    if (path.trim().isEmpty) {
      return errorWidget ?? fallbackError;
    }

    // 1. Base64 Data URL desteği (Web & Mobil ortak kalıcı format)
    if (path.startsWith('data:image')) {
      try {
        final bytes = _base64Cache.putIfAbsent(path, () {
          final base64Data = path.split(',').last;
          return base64Decode(base64Data);
        });
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => errorWidget ?? fallbackError,
        );
      } catch (_) {
        return errorWidget ?? fallbackError;
      }
    }

    // 2. Web Ortamı Veya Network URL
    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
      return Image.network(
        path,
        height: height,
        width: width,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => errorWidget ?? fallbackError,
      );
    }

    // 3. Mobil Cihaz Dosya Yolu
    try {
      return Image.file(
        File(path),
        height: height,
        width: width,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => errorWidget ?? fallbackError,
      );
    } catch (_) {
      return errorWidget ?? fallbackError;
    }
  }
}
