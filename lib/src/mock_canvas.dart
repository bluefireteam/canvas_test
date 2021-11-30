import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:test/fake.dart';
import 'package:vector_math/vector_math_64.dart';

import 'assertion_mode.dart';
import 'canvas_commands/canvas_command.dart';
import 'canvas_commands/cliprect_command.dart';
import 'canvas_commands/image_command.dart';
import 'canvas_commands/line_command.dart';
import 'canvas_commands/paragraph_command.dart';
import 'canvas_commands/rect_command.dart';
import 'canvas_commands/rrect_command.dart';
import 'canvas_commands/transform_command.dart';

/// [MockCanvas] is a utility class for writing tests. It supports the same API
/// as the regular [Canvas] class from dart:ui (in theory; any missing commands
/// can be added as the need arises). In addition, this class is also a
/// [Matcher], allowing it to be used in `expect()` calls:
/// ```dart
/// final canvas = MockCanvas();
/// // ... draw something on the canvas
/// // then check that the commands issued were the ones that you'd expect:
/// expect(
///   canvas,
///   MockCanvas()
///     ..translate(10, 10)
///     ..drawRect(const Rect.fromLTWH(0, 0, 100, 100)),
/// );
/// ```
///
/// Two mock canvases will match only if they have the same number of commands,
/// and if each pair of corresponding commands matches.
///
/// Multiple transform commands (`translate()`, `scale()`, `rotate()` and
/// `transform()`) that are issued in a row are always joined into a single
/// combined transform. Thus, for example, calling `translate(10, 10)` and
/// then `translate(30, -10)` will match a single call `translate(40, 0)`.
///
/// Some commands can be partially specified. For example, in `drawLine()` and
/// `drawRect()` the `paint` argument is optional. If provided, it will be
/// checked against the actual Paint used, but if omitted, the match will still
/// succeed.
///
/// Commands that involve numeric components (i.e. coordinates, dimensions,
/// etc) will be matched approximately, with the default absolute tolerance of
/// 1e-10.
class MockCanvas extends Fake implements Canvas, Matcher {
  MockCanvas({this.mode = AssertionMode.matchExactly})
      : commands = [],
        saveStack = [],
        saveCount = 0;

  final AssertionMode mode;
  final List<CanvasCommand> commands;

  int saveCount;
  final List<Matrix4> saveStack;

  /// The absolute tolerance used when comparing numeric quantities for
  /// equality. Two numeric variables `x` and `y` are considered equal if they
  /// are within the distance [tolerance] from each other.
  ///
  /// When comparing two [MockCanvas] objects, the largest of their respective
  /// [tolerance]s is used.
  double tolerance = 1e-10;

  //#region Matcher API

  @override
  bool matches(covariant MockCanvas other, Map matchState) {
    switch (mode) {
      case AssertionMode.matchExactly:
        return matchExactly(other, matchState);
      case AssertionMode.containsAnyOrder:
        return containsAnyOrder(other, matchState);
    }
  }

  @override
  Description describe(Description description) {
    description.add('Canvas {\n${commands.join('\n')}\n}');
    return description;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    return mismatchDescription.add(matchState['description'] as String);
  }

  bool matchExactly(covariant MockCanvas other, Map matchState) {
    if (saveCount != 0) {
      return _fail('Canvas finished with saveCount=$saveCount', matchState);
    }
    final n1 = commands.length;
    final n2 = other.commands.length;
    if (n1 != n2) {
      return _fail(
        'Canvas contains $n2 commands, but $n1 expected',
        matchState,
      );
    }
    final useTolerance = max(tolerance, other.tolerance);
    for (var i = 0; i < n1; i++) {
      final cmd1 = commands[i];
      final cmd2 = other.commands[i];
      if (cmd1.runtimeType != cmd2.runtimeType) {
        return _fail(
          'Mismatched canvas commands at index $i: the actual '
          'command is ${cmd1.runtimeType}, while the expected '
          'was ${cmd2.runtimeType}',
          matchState,
        );
      }
      cmd1.tolerance = useTolerance;
      if (!cmd1.equals(cmd2)) {
        return _fail(
          'Mismatched canvas commands at index $i: the actual '
          'command is ${cmd1.toString()}, while the expected '
          'was ${cmd2.toString()}',
          matchState,
        );
      }
    }
    return true;
  }

  bool containsAnyOrder(covariant MockCanvas other, Map matchState) {
    if (saveCount != 0) {
      return _fail('Canvas finished with saveCount=$saveCount', matchState);
    }
    final useTolerance = max(tolerance, other.tolerance);
    final remainingActualCommands = other.commands.toList();
    for (final expectedCommand in commands) {
      final idx = remainingActualCommands.indexWhere((cmd) {
        if (expectedCommand.runtimeType != cmd.runtimeType) {
          return false;
        }

        expectedCommand.tolerance = cmd.tolerance = useTolerance;
        return expectedCommand.equals(cmd);
      });
      if (idx == -1) {
        return _fail(
          'Expected canvas command not found: $expectedCommand}. '
          'Actual commands:\n${commands.join('\n')}',
          matchState,
        );
      } else {
        remainingActualCommands.removeAt(idx);
      }
    }
    return true;
  }

  //#endregion

  //#region Canvas API

  @override
  void transform(Float64List matrix4) {
    _lastTransform.transform(matrix4);
  }

  @override
  void translate(double dx, double dy) {
    _lastTransform.translate(dx, dy);
  }

  @override
  void rotate(double angle) {
    _lastTransform.rotate(angle);
  }

  @override
  void scale(double sx, [double? sy]) {
    sy ??= sx;
    _lastTransform.scale(sx, sy);
  }

  @override
  void clipRect(
    Rect rect, {
    ClipOp clipOp = ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    commands.add(ClipRectCommand(rect, clipOp, doAntiAlias));
  }

  @override
  void drawRect(Rect rect, [Paint? paint]) {
    commands.add(RectCommand(rect, paint));
  }

  @override
  void drawRRect(RRect rrect, [Paint? paint]) {
    commands.add(RRectCommand(rrect, paint));
  }

  @override
  void drawLine(Offset p1, Offset p2, [Paint? paint]) {
    commands.add(LineCommand(p1, p2, paint));
  }

  @override
  void drawParagraph(Paragraph? paragraph, Offset offset) {
    commands.add(ParagraphCommand(offset));
  }

  @override
  void drawImage(Image? image, Offset offset, [Paint? paint]) {
    // don't compare the actual images as that would be slow, brittle and hard to test
    commands.add(ImageCommand(offset, paint));
  }

  @override
  int getSaveCount() => saveCount;

  @override
  void restore() {
    saveCount--;
    final savedTransform = saveStack.removeLast();
    if (savedTransform == _currentTransform.matrix) {
      return;
    }
    _lastTransform.setFrom(savedTransform);
  }

  @override
  void save() {
    saveCount++;
    saveStack.add(_currentTransform.matrix.clone());
  }

  //#endregion

  //#region Private helpers

  TransformCommand get _currentTransform {
    final transforms = commands.whereType<TransformCommand>();
    return transforms.isEmpty ? TransformCommand() : transforms.last;
  }

  bool get _isLastCommandTransform =>
      commands.isNotEmpty && commands.last is TransformCommand;

  TransformCommand get _lastTransform {
    if (_isLastCommandTransform) {
      return commands.last as TransformCommand;
    }
    final transform2d = TransformCommand();
    commands.add(transform2d);
    return transform2d;
  }

  bool _fail(String reason, Map state) {
    state['description'] = reason;
    return false;
  }

  //#endregion
}
