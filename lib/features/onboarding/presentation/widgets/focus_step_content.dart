import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../media/data/bunny_images.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../domain/onboarding_step.dart';
import '../providers/onboarding_controller.dart';
import 'choice_step_content.dart';
import 'onboarding_viewport.dart';

/// Width / height of the trimmed figure picture (`where-should-we-focus`).
const _figureAspect = 0.5498;

/// Body-silhouette multi-select, like the reference: a big figure with the
/// pills on its left and right edges, level with the body part each one
/// names. Choosing one lights that part of the body up.
class FocusStepContent extends ConsumerWidget {
  const FocusStepContent({super.key, required this.step, this.binding});

  final FocusStep step;
  final SelectionBinding? binding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final Set<String> selected =
        binding?.selected ??
        ref.watch(
          onboardingControllerProvider.select(
            (s) => s.selections[step.id] ?? const <String>{},
          ),
        );

    // The figure is sized to the room below the headline, so the whole
    // screen fits without scrolling.
    final room = OnboardingViewport.maybeOf(context) ?? 560.0;
    return LayoutBuilder(
      builder: (context, box) {
        final maxH = (room - AppSpacing.lg).clamp(200.0, 900.0);
        final figureH =
            (box.maxWidth - 2 * AppSpacing.md) / _figureAspect < maxH
            ? (box.maxWidth - 2 * AppSpacing.md) / _figureAspect
            : maxH;
        final figureW = figureH * _figureAspect;
        return SizedBox(
          height: room,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: (box.maxWidth - figureW) / 2,
                top: 0,
                width: figureW,
                height: figureH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: _glowing(selected, context)),
                  ],
                ),
              ),
              for (final area in step.areas)
                _FocusPill(
                  area: area,
                  height: figureH,
                  selected: selected.contains(area.id),
                  sideInset: AppSpacing.md,
                  onTap: () => binding != null
                      ? binding!.onToggle(area.id)
                      : controller.toggleOption(step.id, area.id, multi: true),
                ),
            ],
          ),
        );
      },
    );
  }
}

extension on FocusStepContent {
  /// The figure with a soft glow on each chosen part of the body. The glows
  /// are painted with `srcATop` inside their own layer, so they land only
  /// on the figure's pixels, never on the space around it.
  Widget _glowing(Set<String> selected, BuildContext context) {
    final figure = BunnyImage(
      _figureKey,
      fit: BoxFit.fill,
      fallback: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(120),
            bottom: Radius.circular(24),
          ),
          child: const MediaPlaceholder(
            brief: 'Full-length athletic woman, front view, neutral stance',
          ),
        ),
      ),
    );
    final url = BunnyImages.url(_figureKey);
    return Stack(
      fit: StackFit.expand,
      children: [
        figure,
        if (url != null)
          _GlowLayer(
            image: CachedNetworkImageProvider(url.toString()),
            areas: step.areas,
            selected: selected,
          ),
      ],
    );
  }
}

const _figureKey = 'onboarding/your-plan/where-should-we-focus';

/// The glows of every chosen area, each fading in and out on its own, cut
/// to the figure's outline by the figure picture's own transparency.
class _GlowLayer extends StatefulWidget {
  const _GlowLayer({
    required this.image,
    required this.areas,
    required this.selected,
  });

  final ImageProvider image;
  final List<FocusArea> areas;
  final Set<String> selected;

  @override
  State<_GlowLayer> createState() => _GlowLayerState();
}

class _GlowLayerState extends State<_GlowLayer> with TickerProviderStateMixin {
  late final Map<String, AnimationController> _fade = {
    for (final a in widget.areas)
      a.id: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 460),
        value: widget.selected.contains(a.id) ? 1 : 0,
      ),
  };
  ui.Image? _mask;
  ImageStream? _stream;
  late final _listener = ImageStreamListener((info, _) {
    if (mounted) setState(() => _mask = info.image);
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream?.removeListener(_listener);
    _stream = widget.image.resolve(createLocalImageConfiguration(context))
      ..addListener(_listener);
  }

  @override
  void didUpdateWidget(_GlowLayer old) {
    super.didUpdateWidget(old);
    for (final e in _fade.entries) {
      final on = widget.selected.contains(e.key);
      if (MediaQuery.disableAnimationsOf(context)) {
        e.value.value = on ? 1 : 0;
      } else {
        e.value.animateTo(on ? 1 : 0, curve: AppCurves.standard);
      }
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    for (final c in _fade.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mask = _mask;
    if (mask == null) return const SizedBox.expand();
    return IgnorePointer(
      child: CustomPaint(
        painter: _GlowPainter(
          mask: mask,
          glows: [
            for (final a in widget.areas) (spots: a.glow, t: _fade[a.id]!),
          ],
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// The glow colour: a bright coral pink that reads on any outfit colour.
const _glowColor = Color(0xFFFF4F79);

/// Soft blurred ellipses over the chosen body parts, drawn in their own
/// layer and then kept only where the figure picture has pixels.
class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.mask, required this.glows})
    : super(repaint: Listenable.merge([for (final g in glows) g.t]));

  final ui.Image mask;
  final List<({List<GlowSpot> spots, Animation<double> t})> glows;

  @override
  void paint(Canvas canvas, Size size) {
    if (glows.every((g) => g.t.value == 0)) return;
    final bounds = Offset.zero & size;
    final w = size.width;
    canvas.saveLayer(bounds, Paint());
    for (final g in glows) {
      final t = g.t.value;
      if (t == 0) continue;
      for (final spot in g.spots) {
        final rx = spot.radius * w;
        final ry = rx * spot.stretch;
        final paint = Paint()
          ..color = _glowColor.withValues(alpha: 0.8 * t)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, rx * 0.42);
        canvas
          ..save()
          ..translate(spot.x * w, spot.y * size.height)
          ..rotate(spot.angle * math.pi / 180)
          ..drawOval(
            Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
            paint,
          )
          ..restore();
      }
    }
    // Keep the glow only on the body.
    canvas
      ..drawImageRect(
        mask,
        Rect.fromLTWH(0, 0, mask.width.toDouble(), mask.height.toDouble()),
        bounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..filterQuality = FilterQuality.medium,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.mask != mask || old.glows != glows;
}

/// A pill like the reference's: white with a rose dot when off; a coral
/// gradient with a ticked circle and a soft glow when on.
class _FocusPill extends StatelessWidget {
  const _FocusPill({
    required this.area,
    required this.height,
    required this.selected,
    required this.sideInset,
    required this.onTap,
  });

  final FocusArea area;
  final double height;
  final bool selected;
  final double sideInset;
  final VoidCallback onTap;

  static const _pillHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final onRight = area.xFraction >= 0.5;
    final pill = Semantics(
      button: true,
      selected: selected,
      label: area.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedScale(
          scale: selected ? 1.04 : 1,
          duration: AppDurations.selection,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: AppDurations.selection,
            curve: AppCurves.standard,
            height: _pillHeight,
            constraints: const BoxConstraints(minWidth: 128),
            padding: const EdgeInsets.fromLTRB(8, 0, 22, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_pillHeight),
              color: selected ? null : c.surface,
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFFF7E98), Color(0xFFEF5B82)],
                    )
                  : null,
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.35)
                    : c.softRose,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? const Color(0xFFEF5B82).withValues(alpha: 0.38)
                      : c.textPrimary.withValues(alpha: 0.08),
                  blurRadius: selected ? 18 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppDurations.selection,
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : c.softRose.withValues(alpha: 0.7),
                    border: selected
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.4,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: AppDurations.selection,
                    transitionBuilder: (child, a) =>
                        ScaleTransition(scale: a, child: child),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey('on'),
                            size: 20,
                            color: Colors.white,
                          )
                        : Container(
                            key: const ValueKey('off'),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEF5B82),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  area.label,
                  style: AppTypography.title(
                    16,
                    selected ? Colors.white : c.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Positioned(
      left: onRight ? null : sideInset,
      right: onRight ? sideInset : null,
      top: area.yFraction * height - _pillHeight / 2,
      child: pill,
    );
  }
}
