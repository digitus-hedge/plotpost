import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PropertyImage extends StatelessWidget {
  const PropertyImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.errorBuilder,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('data:image/')) {
      final separator = path.indexOf(',');
      if (separator > 0) {
        return Image.memory(
          base64Decode(path.substring(separator + 1)),
          fit: fit,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          errorBuilder: errorBuilder,
        );
      }
    }

    final uri = Uri.tryParse(path);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        errorBuilder: errorBuilder,
      );
    }

    if (kIsWeb) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        errorBuilder: errorBuilder,
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      errorBuilder: errorBuilder,
    );
  }
}
