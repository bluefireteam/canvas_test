# Canvas test helpers

[MockCanvas] is a utility class for writing tests. It supports the same API
as the regular [Canvas] class from dart:ui (in theory; any missing commands
can be added as the need arises). In addition, this class is also a
[Matcher], allowing it to be used in `expect()` calls as can be seen in the
example below.

Two mock canvases will match only if they have the same number of commands,
and if each pair of corresponding commands matches.

Multiple transform commands (`translate()`, `scale()`, `rotate()` and
`transform()`) that are issued in a row are always joined into a single
combined transform. Thus, for example, calling `translate(10, 10)` and
then `translate(30, -10)` will match a single call `translate(40, 0)`.

Some commands can be partially specified. For example, in `drawLine()` and
`drawRect()` the `paint` argument is optional. If provided, it will be
checked against the actual Paint used, but if omitted, the match will still
succeed.

Commands that involve numeric components (i.e. coordinates, dimensions,
etc) will be matched approximately, with the default absolute tolerance of
1e-10.

## Example Usage

```dart
final canvas = MockCanvas();
// ... draw something on the canvas
// then check that the commands issued were the ones that you'd expect:
expect(
  canvas,
  MockCanvas()
    ..translate(10, 10)
    ..drawRect(const Rect.fromLTWH(0, 0, 100, 100)),
);
```
