import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'bone.dart';
import 'hints.dart';
import 'theme.dart';

/// Where font lines sit, in ems from the baseline (up is positive).
///
/// Flutter exposes a line's ascent and descent but not glyph ink, so these
/// are typical values for UI fonts (Roboto, SF, Inter) rather than measured.
const Map<TextTop, double> kTextTopEm = {
  TextTop.ascender: 0.74,
  TextTop.capHeight: 0.70,
  TextTop.xHeight: 0.52,
};
const Map<TextBottom, double> kTextBottomEm = {
  TextBottom.baseline: 0,
  TextBottom.descender: 0.21,
};

/// A container's own paint (card, sheet, tinted box) that stays visible
/// under the bones it holds.
class FlankrSurface {
  const FlankrSurface(this.transform, this.size, this.paint, {this.clip = Rect.largest});

  final Matrix4 transform;
  final Size size;

  /// What the surface is clipped to, in the skeleton's space (a scroll view, say).
  final Rect clip;
  final void Function(Canvas canvas, Size size) paint;
}

/// What a laid-out widget tree looks like as a skeleton.
class FlankrMeasurement {
  const FlankrMeasurement(this.shape, this.surfaces);

  final BoneShape shape;
  final List<FlankrSurface> surfaces;
}

/// Measures what [root] holds into bones relative to its top-left.
///
/// [root] must have been laid out. Nothing in the tree is changed.
FlankrMeasurement measureBones(RenderBox root, FlankrStyle style) {
  final measurer = _Measurer(style);
  measurer.visit(root, Matrix4.identity(), const _Context());
  return FlankrMeasurement(
    BoneShape(size: root.size, bones: List.unmodifiable(measurer.bones)),
    List.unmodifiable(measurer.surfaces),
  );
}

class _Context {
  const _Context({
    this.clip = Rect.largest,
    this.shape,
    this.shapeRadius = 0,
    this.inButton = false,
  });

  /// Everything outside this is clipped away.
  final Rect clip;

  /// The nearest rounded clip, whose radius media inside it take on.
  final Rect? shape;
  final double shapeRadius;
  final bool inButton;

  _Context clipTo(Rect rect, {double? radius}) => _Context(
        clip: clip.intersect(rect),
        shape: radius == null ? shape : rect,
        shapeRadius: radius ?? shapeRadius,
        inButton: inButton,
      );

  _Context get button => _Context(clip: clip, shape: shape, shapeRadius: shapeRadius, inButton: true);
}

class _Measurer {
  _Measurer(this.style);

  final FlankrStyle style;
  final List<Bone> bones = [];
  final List<FlankrSurface> surfaces = [];

  void visitChildren(RenderObject node, Matrix4 transform, _Context ctx) {
    node.visitChildrenForSemantics((child) {
      final childTransform = transform.clone();
      node.applyPaintTransform(child, childTransform);
      visit(child, childTransform, ctx);
    });
  }

  void visit(RenderObject node, Matrix4 transform, _Context ctx) {
    if (node is RenderFlankrIgnore) return;
    if (node is! RenderBox) return visitChildren(node, transform, ctx);
    if (!node.hasSize) return;
    final rect = MatrixUtils.transformRect(transform, Offset.zero & node.size);

    switch (node) {
      case RenderFlankrBlock():
        return block(rect, node.radius ?? style.radius, ctx, inherit: node.radius == null);
      case RenderParagraph():
        return paragraph(node, transform, rect, ctx);
      case RenderEditable() || RenderImage():
        return block(rect, style.radius, ctx);
      case RenderCustomPaint(child: null) when node.painter != null || node.foregroundPainter != null:
        return block(rect, style.radius, ctx);
      case RenderDecoratedBox():
        return decorated(node, transform, rect, ctx);
      case RenderPhysicalModel() || RenderPhysicalShape():
        return physical(node, transform, rect, ctx);
      case RenderSemanticsAnnotations() when node.properties.button ?? false:
        return visitChildren(node, transform, ctx.button);
      case RenderClipRRect():
        final radius = _radius(node.borderRadius, node.textDirection);
        return visitChildren(node, transform, ctx.clipTo(rect, radius: radius));
      case RenderClipOval():
        return visitChildren(node, transform, ctx.clipTo(rect, radius: rect.shortestSide / 2));
      case RenderClipRect() || RenderViewportBase():
        return visitChildren(node, transform, ctx.clipTo(rect));
      default:
        return visitChildren(node, transform, ctx);
    }
  }

  /// One block. Unless [inherit] is false, a block that fills a rounded clip
  /// or container takes on its radius — an image in a rounded card, say.
  void block(Rect rect, double radius, _Context ctx, {bool inherit = true}) {
    final clipped = rect.intersect(ctx.clip);
    if (clipped.width < 1 || clipped.height < 1) return;
    final shape = ctx.shape;
    final fills = inherit && shape != null && _fills(clipped, shape);
    bones.add(Bone(clipped, fills ? ctx.shapeRadius : radius));
  }

  void paragraph(RenderParagraph node, Matrix4 transform, Rect rect, _Context ctx) {
    final text = node.text.toPlainText(includeSemanticsLabels: false, includePlaceholders: false);
    if (text.trim().isEmpty) return;
    if (_isIcon(node, text)) return block(rect, style.radius, ctx);

    final paragraphClip = node.overflow == TextOverflow.visible ? ctx.clip : ctx.clip.intersect(rect);
    if (node.childCount > 0) return _paragraphBoxes(node, transform, paragraphClip);

    // Lay out exactly as RenderParagraph does, so wrapping and alignment match.
    final widthMatters = node.softWrap || node.overflow == TextOverflow.ellipsis;
    final painter = TextPainter(
      text: node.text,
      textAlign: node.textAlign,
      textDirection: node.textDirection,
      textScaler: node.textScaler,
      maxLines: node.maxLines,
      ellipsis: node.overflow == TextOverflow.ellipsis ? '…' : null,
      locale: node.locale,
      strutStyle: node.strutStyle,
      textWidthBasis: node.textWidthBasis,
      textHeightBehavior: node.textHeightBehavior,
    )..layout(
        minWidth: node.constraints.minWidth,
        maxWidth: widthMatters ? node.constraints.maxWidth : double.infinity,
      );

    final em = node.textScaler.scale(node.text.style?.fontSize ?? 14);
    final up = em * kTextTopEm[style.text.top]!;
    final down = em * kTextBottomEm[style.text.bottom]!;
    for (final ui.LineMetrics line in painter.computeLineMetrics()) {
      if (line.width < 0.5) continue;
      final local = Rect.fromLTRB(line.left, line.baseline - up, line.left + line.width, line.baseline + down);
      final bar = MatrixUtils.transformRect(transform, local).intersect(paragraphClip);
      if (bar.width >= 1 && bar.height >= 1) bones.add(Bone(bar, style.radius));
    }
    painter.dispose();
  }

  /// Text with inline widgets: one bar per line, from the paragraph's own
  /// glyph boxes (which already account for the widgets' sizes).
  void _paragraphBoxes(RenderParagraph node, Matrix4 transform, Rect clip) {
    final length = node.text.toPlainText(includeSemanticsLabels: false).length;
    final boxes = node.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: length));
    final lines = <Rect>[];
    for (final box in boxes) {
      final r = box.toRect();
      if (r.width < 0.5) continue;
      final i = lines.indexWhere((l) => r.top < l.bottom && r.bottom > l.top);
      if (i < 0) {
        lines.add(r);
      } else {
        lines[i] = lines[i].expandToInclude(r);
      }
    }
    for (final line in lines) {
      final bar = MatrixUtils.transformRect(transform, line).intersect(clip);
      if (bar.width >= 1 && bar.height >= 1) bones.add(Bone(bar, style.radius));
    }
  }

  void decorated(RenderDecoratedBox node, Matrix4 transform, Rect rect, _Context ctx) {
    final decoration = node.decoration;
    final radius = _radiusOfDecoration(decoration, rect, node.configuration.textDirection);
    if (decoration is BoxDecoration && decoration.image != null) {
      return block(rect, radius, ctx);
    }
    if (!_paints(decoration) || node.position == DecorationPosition.foreground) {
      return visitChildren(node, transform, ctx);
    }
    final configuration = node.configuration;
    surface(node, transform, rect, radius, ctx, (canvas, size) {
      final painter = decoration.createBoxPainter(() {});
      painter.paint(canvas, Offset.zero, configuration.copyWith(size: size));
      painter.dispose();
    });
  }

  void physical(RenderBox node, Matrix4 transform, Rect rect, _Context ctx) {
    final (color, shadow, elevation, path) = switch (node) {
      final RenderPhysicalModel m => (m.color, m.shadowColor, m.elevation, _modelPath(m)),
      final RenderPhysicalShape s => (s.color, s.shadowColor, s.elevation, s.clipper!.getClip(s.size)),
      _ => throw StateError('not physical'),
    };
    if (color.a == 0 && elevation == 0) return visitChildren(node, transform, ctx);
    final radius = _radiusOfPhysical(node, rect);
    surface(node, transform, rect, radius, ctx, (canvas, size) {
      if (elevation > 0) canvas.drawShadow(path, shadow, elevation, color.a < 1);
      canvas.drawPath(path, Paint()..color = color);
    });
  }

  /// A container keeps its surface and its contents become bones; one that
  /// holds nothing to draw (or is a button) is drawn as a block instead.
  void surface(
    RenderBox node,
    Matrix4 transform,
    Rect rect,
    double radius,
    _Context ctx,
    void Function(Canvas, Size) paint,
  ) {
    if (ctx.inButton) return block(rect, radius, ctx);
    final surfaceIndex = surfaces.length;
    final boneCount = bones.length;
    final inner = _Context(clip: ctx.clip, shape: rect, shapeRadius: radius, inButton: ctx.inButton);
    visitChildren(node, transform, inner);
    if (bones.length == boneCount) {
      surfaces.removeRange(surfaceIndex, surfaces.length);
      return block(rect, radius, ctx);
    }
    surfaces.insert(surfaceIndex, FlankrSurface(transform, node.size, paint, clip: ctx.clip));
  }

  static bool _fills(Rect rect, Rect shape) =>
      (rect.left - shape.left).abs() <= 2 &&
      (rect.top - shape.top).abs() <= 2 &&
      (rect.right - shape.right).abs() <= 2 &&
      (rect.bottom - shape.bottom).abs() <= 2;

  static bool _isIcon(RenderParagraph node, String text) {
    final runes = text.runes.toList();
    if (runes.length != 1) return false;
    final cp = runes.first;
    if ((cp >= 0xE000 && cp <= 0xF8FF) || cp >= 0xF0000) return true;
    final family = node.text.style?.fontFamily ?? '';
    return family.contains('Icons') || family.contains('Cupertino');
  }

  static bool _paints(Decoration d) => switch (d) {
        BoxDecoration() => (d.color?.a ?? 0) > 0 ||
            d.gradient != null ||
            d.border != null ||
            (d.boxShadow?.isNotEmpty ?? false),
        ShapeDecoration() =>
          (d.color?.a ?? 0) > 0 || d.gradient != null || (d.shadows?.isNotEmpty ?? false),
        _ => true,
      };

  double _radiusOfDecoration(Decoration d, Rect rect, TextDirection? dir) => switch (d) {
        BoxDecoration(shape: BoxShape.circle) => rect.shortestSide / 2,
        BoxDecoration(:final borderRadius?) => _radius(borderRadius, dir),
        BoxDecoration() => 0,
        ShapeDecoration(:final shape) => _radiusOfShape(shape, rect, dir),
        _ => style.radius,
      };

  double _radiusOfPhysical(RenderBox node, Rect rect) => switch (node) {
        RenderPhysicalModel(shape: BoxShape.circle) => rect.shortestSide / 2,
        RenderPhysicalModel(:final borderRadius) => borderRadius?.topLeft.x ?? 0,
        RenderPhysicalShape(:final clipper) when clipper is ShapeBorderClipper =>
          _radiusOfShape(clipper.shape, rect, clipper.textDirection),
        _ => style.radius,
      };

  double _radiusOfShape(ShapeBorder shape, Rect rect, TextDirection? dir) => switch (shape) {
        CircleBorder() || StadiumBorder() => rect.shortestSide / 2,
        RoundedRectangleBorder(:final borderRadius) => _radius(borderRadius, dir),
        ContinuousRectangleBorder(:final borderRadius) => _radius(borderRadius, dir) * 0.5,
        _ => style.radius,
      };

  /// The start-top corner's radius; directional radii resolve left-to-right
  /// when no direction is known.
  static double _radius(BorderRadiusGeometry radius, TextDirection? dir) =>
      radius.resolve(dir ?? TextDirection.ltr).topLeft.x;

  static Path _modelPath(RenderPhysicalModel node) {
    final rect = Offset.zero & node.size;
    if (node.shape == BoxShape.circle) return Path()..addOval(rect);
    return Path()..addRRect((node.borderRadius ?? BorderRadius.zero).toRRect(rect));
  }
}
