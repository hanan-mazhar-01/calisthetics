import 'package:flutter/material.dart';

/// A physical-folder silhouette: a rounded body with a smaller rounded tab
/// peeking above its top-left — used to clip [GlassFolder] into something
/// more specific than a plain rounded rectangle.
class GlassFolderShape extends CustomClipper<Path> {
  const GlassFolderShape();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    const bodyRadius = 22.0;
    const tabRadius = 12.0;
    final tabWidth = w * 0.52;
    final tabHeight = h * 0.16;
    final bodyTop = tabHeight * 0.6;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, bodyTop, w, h - bodyTop),
      const Radius.circular(bodyRadius),
    );
    final tab = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, tabWidth, tabHeight),
      topLeft: const Radius.circular(bodyRadius),
      topRight: const Radius.circular(tabRadius),
    );

    return Path()
      ..addRRect(tab)
      ..addRRect(body);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
