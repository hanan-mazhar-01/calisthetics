import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../domain/onboarding_step.dart';

/// A single selectable row: an elevated white card that becomes a soft pink
/// gradient once selected. Multi-select screens show a checkbox circle on
/// the left. When the option has a photo, it bleeds full-height to the
/// card's right edge (clipped by the card's own rounded corners) rather
/// than sitting inset as a small thumbnail; a plain glyph option keeps the
/// smaller inset badge instead, since it doesn't carry a photo's weight.
/// Selected state is pure `Animated*` — no controller needed since it's
/// driven by Riverpod state.
class ChoiceListTile extends StatelessWidget {
  const ChoiceListTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    required this.multi,
    this.minHeight = 0,
  });

  final ChoiceOption option;
  final bool selected;
  final VoidCallback onTap;
  final bool multi;

  /// Floor for the main row only — the feedback panel (when shown) adds on
  /// top of this instead of sharing it, so selecting an option grows the
  /// card taller rather than squeezing the row to make room.
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AnimatedScale(
        scale: selected ? 1.015 : 1,
        duration: AppDurations.selection,
        curve: AppCurves.standard,
        child: AnimatedContainer(
          duration: AppDurations.selection,
          curve: AppCurves.standard,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: selected ? null : context.appColors.surface,
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      context.appColors.softRose,
                      context.appColors.accent,
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: context.appColors.textPrimary.withValues(
                  alpha: selected ? 0.06 : 0.03,
                ),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (multi)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.lg,
                              ),
                              child: Center(
                                child: _CheckboxCircle(selected: selected),
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      option.label,
                                      style: AppTypography.title(
                                        17,
                                        context.appColors.textPrimary,
                                        weight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                    if (option.description != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        option.description!,
                                        style: AppTypography.body(
                                          context.appColors.textSecondary,
                                          fontSize: 13.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (option.imageKey != null)
                            _OptionPicture(option: option)
                          else if (option.imagePrompt != null)
                            SizedBox(
                              width: 108,
                              child: MediaPlaceholder(
                                brief: option.imagePrompt!,
                              ),
                            )
                          else if (option.glyph != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.lg,
                              ),
                              child: Center(
                                child: _GlyphBadge(glyph: option.glyph!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (option.feedbackBody != null)
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedCrossFade(
                        duration: AppDurations.selection,
                        sizeCurve: AppCurves.standard,
                        firstCurve: AppCurves.standard,
                        secondCurve: AppCurves.standard,
                        crossFadeState: selected
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: _InlineFeedback(
                          lead: option.feedbackLead ?? '',
                          body: option.feedbackBody!,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The option's picture on the right of the card: a photo of a person bleeds
/// to the card edge; a 3D icon sits inside it. Until the image is available
/// (or if it can't load) the old placeholder / letter badge shows.
class _OptionPicture extends StatelessWidget {
  const _OptionPicture({required this.option});

  final ChoiceOption option;

  @override
  Widget build(BuildContext context) {
    final fallback = option.imagePrompt != null
        ? MediaPlaceholder(brief: option.imagePrompt!)
        : option.glyph != null
        ? Center(child: _GlyphBadge(glyph: option.glyph!))
        : null;
    // The picture only fills the room the card already has (a Stack of
    // positioned children has no height of its own), so a tall image can
    // never stretch its card taller than the others.
    if (option.photo) {
      // Whole figure, standing on the card's bottom edge: nothing is cropped.
      return SizedBox(
        width: 122,
        child: Stack(
          children: [
            Positioned.fill(
              child: BunnyImage(
                option.imageKey!,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                fallback: fallback,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: 100,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
              child: BunnyImage(
                option.imageKey!,
                fit: BoxFit.contain,
                fallback: fallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "what does this mean" info panel that drops in under a selected
/// option — styled as its own white section (divider on top, small icon
/// bubble leading the copy) rather than just more text on the gradient,
/// so it reads as supporting detail rather than part of the label.
class _InlineFeedback extends StatelessWidget {
  const _InlineFeedback({required this.lead, required this.body});

  final String lead;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(
          top: BorderSide(color: context.appColors.divider, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 10, top: 1),
              decoration: BoxDecoration(
                color: context.appColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🤖', style: TextStyle(fontSize: 12)),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.body(
                    context.appColors.textPrimary,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '$lead ',
                      style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: body),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static illustration chip — doesn't change with selection, matching a
/// plain always-visible icon rather than a reactive indicator.
class _GlyphBadge extends StatelessWidget {
  const _GlyphBadge({required this.glyph});

  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: AppTypography.title(
          22,
          context.appColors.textPrimary,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Left-side checkbox used on multi-select rows — the primary selection
/// indicator there, independent of the static icon on the right.
class _CheckboxCircle extends StatelessWidget {
  const _CheckboxCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.selection,
      curve: AppCurves.standard,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? context.appColors.onAccent : Colors.transparent,
        border: Border.all(
          color: selected
              ? context.appColors.onAccent
              : context.appColors.divider,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: AppDurations.selection,
        curve: AppCurves.overshoot,
        child: Icon(
          Icons.check_rounded,
          size: 16,
          color: context.appColors.accent,
        ),
      ),
    );
  }
}
