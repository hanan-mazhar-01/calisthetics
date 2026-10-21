import 'package:flutter/material.dart';

/// Google's own four-colour "G" mark, drawn as vector paths (Google's
/// branding rules ask for this mark, unaltered, on "Sign in with Google").
/// The 48 x 48 outlines are the ones Google publishes.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Google',
    excludeSemantics: true,
    child: CustomPaint(size: Size.square(size), painter: _GoogleLogoPainter()),
  );
}

const _red = Color(0xFFEA4335);
const _blue = Color(0xFF4285F4);
const _yellow = Color(0xFFFBBC05);
const _green = Color(0xFF34A853);

const googleLogoPaths = <(Color, String)>[
  (
    _red,
    'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 '
        '14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z',
  ),
  (
    _blue,
    'M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 '
        '5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z',
  ),
  (
    _yellow,
    'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19'
        'C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z',
  ),
  (
    _green,
    'M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 '
        '2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z',
  ),
];

class _GoogleLogoPainter extends CustomPainter {
  static final _paths = [
    for (final (color, d) in googleLogoPaths) (color, parseSvgPath(d)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    for (final (color, path) in _paths) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}

/// A small SVG path reader: M L H V C S Z, upper and lower case.
Path parseSvgPath(String d) {
  final tokens = RegExp(r'[a-zA-Z]|-?(?:\d*\.\d+|\d+\.?)')
      .allMatches(d)
      .map((m) => m[0]!)
      .toList();
  final path = Path();
  var i = 0;
  var x = 0.0, y = 0.0; // current point
  var sx = 0.0, sy = 0.0; // start of the sub-path
  var cx = 0.0, cy = 0.0; // last control point (for S)
  String? cmd;
  double next() => double.parse(tokens[i++]);
  bool isCmd(String t) => RegExp(r'^[a-zA-Z]$').hasMatch(t);

  while (i < tokens.length) {
    if (isCmd(tokens[i])) cmd = tokens[i++];
    final c = cmd!;
    final rel = c == c.toLowerCase();
    switch (c.toUpperCase()) {
      case 'M':
        final nx = next() + (rel ? x : 0), ny = next() + (rel ? y : 0);
        path.moveTo(nx, ny);
        x = sx = nx;
        y = sy = ny;
        cx = x;
        cy = y;
        cmd = rel ? 'l' : 'L'; // further pairs are line-tos
      case 'L':
        x = next() + (rel ? x : 0);
        y = next() + (rel ? y : 0);
        path.lineTo(x, y);
        cx = x;
        cy = y;
      case 'H':
        x = next() + (rel ? x : 0);
        path.lineTo(x, y);
        cx = x;
        cy = y;
      case 'V':
        y = next() + (rel ? y : 0);
        path.lineTo(x, y);
        cx = x;
        cy = y;
      case 'C':
        final x1 = next() + (rel ? x : 0), y1 = next() + (rel ? y : 0);
        final x2 = next() + (rel ? x : 0), y2 = next() + (rel ? y : 0);
        final nx = next() + (rel ? x : 0), ny = next() + (rel ? y : 0);
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
      case 'S':
        final x1 = 2 * x - cx, y1 = 2 * y - cy; // reflected control point
        final x2 = next() + (rel ? x : 0), y2 = next() + (rel ? y : 0);
        final nx = next() + (rel ? x : 0), ny = next() + (rel ? y : 0);
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        cx = x2;
        cy = y2;
        x = nx;
        y = ny;
      case 'Z':
        path.close();
        x = sx;
        y = sy;
        cx = x;
        cy = y;
      default:
        throw FormatException('Unsupported path command $c');
    }
  }
  return path;
}
