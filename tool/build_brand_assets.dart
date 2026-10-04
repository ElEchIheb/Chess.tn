// Derives every launcher / splash image from the official chess.tn logo.
//
//   dart run tool/build_brand_assets.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// The logo (assets/branding/chess_tn_logo.png) is the single source of
// truth and is never modified. This script only crops the emblem out of it
// and places the untouched pixels on canvases of the sizes Android and iOS
// expect. Nothing is redrawn, recoloured or distorted.
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const String branding = 'assets/branding';
const String logoPath = '$branding/chess_tn_logo.png';

/// Pixels this opaque or more count as "ink".
const int alphaThreshold = 24;

bool _ink(img.Image image, int x, int y) =>
    image.getPixel(x, y).a > alphaThreshold;

bool _rowHasInk(img.Image image, int y, int fromX, int toX) {
  for (var x = fromX; x <= toX; x++) {
    if (_ink(image, x, y)) return true;
  }
  return false;
}

/// Finds the emblem (chess piece with crescent and star) above the wordmark.
///
/// The wordmark is wider than the emblem, so the first row that has ink in
/// the left margin is where the lettering starts. The emblem's own columns
/// are measured above that row, and its bottom edge is where those columns
/// become empty again.
({int left, int top, int right, int bottom}) findEmblem(img.Image logo) {
  final leftMargin = (logo.width * 0.28).round();
  var top = 0;
  while (!_rowHasInk(logo, top, 0, logo.width - 1)) {
    top++;
  }
  var wordmarkTop = top;
  while (!_rowHasInk(logo, wordmarkTop, 0, leftMargin)) {
    wordmarkTop++;
  }
  var left = logo.width;
  var right = 0;
  for (var y = top; y < wordmarkTop; y++) {
    for (var x = 0; x < logo.width; x++) {
      if (_ink(logo, x, y)) {
        left = min(left, x);
        right = max(right, x);
      }
    }
  }
  var bottom = wordmarkTop;
  while (bottom < logo.height - 1 && _rowHasInk(logo, bottom, left, right)) {
    bottom++;
  }
  return (left: left, top: top, right: right, bottom: bottom - 1);
}

/// [source] scaled to fit inside [maxWidth] x [maxHeight], aspect ratio kept.
img.Image fit(img.Image source, int maxWidth, int maxHeight) {
  final scale = min(maxWidth / source.width, maxHeight / source.height);
  return img.copyResize(
    source,
    width: (source.width * scale).round(),
    height: (source.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
}

/// A square canvas with [content] centred on it.
img.Image canvas(int size, img.Image content, {required bool white}) {
  final out = img.Image(width: size, height: size, numChannels: 4);
  img.fill(
    out,
    color: white
        ? img.ColorRgba8(255, 255, 255, 255)
        : img.ColorRgba8(0, 0, 0, 0),
  );
  img.compositeImage(
    out,
    content,
    dstX: (size - content.width) ~/ 2,
    dstY: (size - content.height) ~/ 2,
  );
  return out;
}

void save(String name, img.Image image) {
  final file = File('$branding/$name')
    ..writeAsBytesSync(img.encodePng(image, level: 9));
  stdout.writeln(
    '  $name  ${image.width}x${image.height}  '
    '${(file.lengthSync() / 1024).round()} KB',
  );
}

void main() {
  final file = File(logoPath);
  if (!file.existsSync()) {
    stderr.writeln('Missing $logoPath — put the official logo there first.');
    exit(1);
  }
  final logo = img.decodePng(file.readAsBytesSync())!;
  stdout.writeln('Official logo: ${logo.width}x${logo.height}');

  final box = findEmblem(logo);
  stdout.writeln(
    'Emblem found at x ${box.left}..${box.right}, y ${box.top}..${box.bottom}',
  );
  final emblem = img.copyCrop(
    logo,
    x: box.left,
    y: box.top,
    width: box.right - box.left + 1,
    height: box.bottom - box.top + 1,
  );

  // In-app emblem (transparent, tight crop).
  save('chess_tn_emblem.png', emblem);

  // Legacy / iOS launcher icon: emblem on white, comfortable margin.
  save('launcher_icon.png', canvas(1024, fit(emblem, 760, 760), white: true));

  // Adaptive icon foreground. flutter_launcher_icons insets it by 16% on
  // every side, and Android guarantees only a circle of 66/108 of the
  // canvas. At 780 px the emblem is 52% of the canvas tall and its corners
  // sit at 0.29 of the canvas from the centre, inside that 0.31 safe radius
  // — so no launcher shape can crop it.
  save(
    'launcher_foreground.png',
    canvas(1024, fit(emblem, 780, 780), white: false),
  );

  // Native splash (before Flutter draws): the full logo on white.
  save('splash_logo.png', canvas(1152, fit(logo, 1152, 1152), white: false));

  // Android 12+ masks the splash icon with a circle of 2/3 of the canvas.
  save(
    'splash_android12.png',
    canvas(1152, fit(emblem, 640, 640), white: false),
  );
  stdout.writeln('Done.');
}
