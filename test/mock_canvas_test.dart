import 'dart:ui';

import 'package:canvas_test/canvas_test.dart';
import 'package:test/test.dart';

void main() {
  group('MockCanvas', () {
    test('drawRect', () {
      final canvas = MockCanvas();
      canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), Paint());
      expectCommand(
        canvas.commands.single,
        RectCommand(const Rect.fromLTWH(0, 0, 100, 100), Paint()),
      );
      expect(
        canvas.commands.single.toString(),
        'drawRect(Rect(0, 0, 100, 100), Paint(Color(0xff000000), BlendMode.srcOver, PaintingStyle.fill, 0))',
      );
    });
    test('drawRRect', () {
      final canvas = MockCanvas();
      canvas.drawRRect(
        RRect.fromRectXY(const Rect.fromLTWH(0, 0, 100, 100), 10, 10),
        Paint(),
      );
      expectCommand(
        canvas.commands.single,
        RRectCommand(
          RRect.fromRectXY(const Rect.fromLTWH(0, 0, 100, 100), 10, 10),
          Paint(),
        ),
      );
      expect(
        canvas.commands.single.toString(),
        'drawRRect(RRect(0, 0, 100, 100, 10, 10, 10, 10, 10, 10, 10, 10), Paint(Color(0xff000000), BlendMode.srcOver, PaintingStyle.fill, 0))',
      );
    });
  });
}

void expectCommand(CanvasCommand actual, CanvasCommand expected) {
  expect(actual.equals(expected), true);
}
