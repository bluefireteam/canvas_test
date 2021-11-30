import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';
import 'canvas_command.dart';

/// This canvas command describes either a single or multiple method calls
/// `canvas.translate()`, `canvas.rotate()`, `canvas.scale()`, or
/// `canvas.transform()`.
class TransformCommand extends CanvasCommand {
  final Matrix4 matrix;

  TransformCommand() : matrix = Matrix4.identity();
  TransformCommand.from(this.matrix);

  void setFrom(Matrix4 matrix) {
    this.matrix.setFrom(matrix);
  }

  void transform(Float64List matrix) {
    this.matrix.multiply(Matrix4.fromFloat64List(matrix));
  }

  void translate(double dx, double dy) => matrix.translate(dx, dy);
  void rotate(double angle) => matrix.rotateZ(angle);
  void scale(double sx, double sy) => matrix.scale(sx, sy, 1);

  @override
  bool equals(TransformCommand other) {
    return eq(matrix.storage, other.matrix.storage);
  }

  @override
  String toString() {
    final content = matrix.storage.map(repr).join(', ');
    return 'transform($content)';
  }
}
