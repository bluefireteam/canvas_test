import 'package:canvas_test/canvas_test.dart';
import 'package:canvas_test_examples/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:test/test.dart';

void main() {
  group('test canvas', () {
    test('test rect on canvas', () {
      final canvas = MockCanvas();
      RectanglePainter().paint(canvas, const Size(100, 100));
      expect(
        canvas,
        MockCanvas()..drawRect(const Rect.fromLTWH(100, 100, 100, 100)),
      );
    });
  });
}
