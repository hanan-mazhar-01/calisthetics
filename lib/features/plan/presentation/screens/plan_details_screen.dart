import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/haptics/haptics.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../onboarding/data/onboarding_flow.dart';
import '../../../onboarding/domain/onboarding_step.dart';
import '../../../plans/data/plan_templates.dart';
import '../../../plans/domain/plan_template.dart';
import '../../../plans/domain/user_profile.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/plan_showcase.dart';
import '../providers/plan_providers.dart';
import '../widgets/plan_showcase_card.dart';
import '../widgets/plan_switch_dialog.dart';
import 'all_plans_screen.dart' show PlanTopBar;

/// One plan in full: its card, the body areas it trains, a short brief, what
/// following it gives, and a Join button. Joining adds the plan and asks
/// whether to switch to it now.
class PlanDetailsScreen extends ConsumerStatefulWidget {
  const PlanDetailsScreen({super.key, required this.templateId});

  final String templateId;

  @override
  ConsumerState<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends ConsumerState<PlanDetailsScreen> {
  bool _busy = false;

  PlanTemplate? get _template =>
      planTemplates.where((t) => t.id == widget.templateId).firstOrNull;

  Future<void> _join(PlanTemplate template) async {
    if (_busy) return;
    // Free keeps one plan: more are Premium.
    if (!ref.read(canAddPlanProvider)) {
      context.push('/paywall');
      return;
    }
    Haptics.medium();
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    final notifier = ref.read(activePlanProvider.notifier);
    final profile =
        ref.read(activePlanProvider)?.profile ?? const UserProfile();
    final otherIsCurrent = await notifier.join(template, profile);
    if (!mounted) return;
    if (otherIsCurrent) {
      final switchNow = await showSwitchPlanDialog(
        context,
        planName: template.name,
      );
      if (switchNow) await notifier.switchTo(template.id);
    }
    router.go('/home');
  }

  Future<void> _switch(PlanTemplate template) async {
    if (_busy) return;
    Haptics.medium();
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    await ref.read(activePlanProvider.notifier).switchTo(template.id);
    router.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final template = _template;
    final c = context.appColors;
    if (template == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: const SafeArea(child: PlanTopBar(title: 'Plan Details')),
      );
    }
    final owned = ref
        .watch(ownedPlansProvider)
        .any((p) => p.templateId == template.id);
    final current = ref.watch(activePlanProvider)?.templateId == template.id;
    final canAdd = ref.watch(canAddPlanProvider);
    final areas = planAreas(template);
    final bottom = MediaQuery.paddingOf(context).bottom;

    final (label, onTap, lock) = current
        ? ('Current plan', null, false)
        : owned
        ? ('Switch to this plan', () => _switch(template), false)
        : ('Join', () => _join(template), !canAdd);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                const PlanTopBar(title: 'Plan Details'),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 110),
                    children: [
                      PlanShowcaseCard(template: template, isCurrent: current),
                      const SizedBox(height: 26),
                      _Title('Focus'),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final id in planAreaIds)
                            _FocusBubble(id: id, selected: areas.contains(id)),
                        ],
                      ),
                      const SizedBox(height: 26),
                      _Title('Brief'),
                      const SizedBox(height: 8),
                      Text(
                        template.description,
                        style: AppTypography.body(
                          c.textSecondary,
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _Title("You'll Gain"),
                      const SizedBox(height: 4),
                      for (final (i, g) in planGains(template).indexed)
                        _GainRow(number: i + 1, text: g, last: i == 3),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.background.withValues(alpha: 0), c.background],
                    stops: const [0, 0.3],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, bottom + 14),
                  child: _JoinButton(
                    label: label,
                    locked: lock,
                    busy: _busy,
                    onTap: onTap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.title(
      19,
      context.appColors.textPrimary,
      weight: FontWeight.w700,
    ),
  );
}

/// A round close-up of one body part (cropped from the focus figure), with a
/// tick when the plan trains it.
class _FocusBubble extends StatelessWidget {
  const _FocusBubble({required this.id, required this.selected});

  final String id;
  final bool selected;

  static const _size = 54.0;
  static const _figureAspect = 0.5498;

  /// Where on the figure (fractions) the area sits: the first glow spot the
  /// onboarding focus screen uses for it.
  static GlowSpot? _spot(String id) {
    for (final step in onboardingSteps) {
      if (step is FocusStep) {
        for (final a in step.areas) {
          if (a.id == id && a.glow.isNotEmpty) return a.glow.first;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final spot = _spot(id);
    const zoom = 3.4;
    const w = _size * zoom;
    const h = w / _figureAspect;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.softRose,
                    border: selected
                        ? Border.all(color: c.accent, width: 2)
                        : null,
                  ),
                  child: ClipOval(
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        if (spot != null)
                          Positioned(
                            left: _size / 2 - spot.x * w,
                            top: _size / 2 - spot.y * h,
                            width: w,
                            height: h,
                            child: const BunnyImage(
                              'onboarding/your-plan/where-should-we-focus',
                              fit: BoxFit.fill,
                              cacheWidth: 700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.background, width: 2),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: c.onAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          planAreaLabels[id]!,
          style: AppTypography.body(
            selected ? c.textPrimary : c.textMuted,
            fontSize: 12.5,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _GainRow extends StatelessWidget {
  const _GainRow({
    required this.number,
    required this.text,
    required this.last,
  });

  final int number;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.softRose,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppTypography.title(
                13.5,
                c.accentText,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(
                c.textPrimary,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom button: Join, Switch to this plan, or the greyed Current plan.
class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.label,
    required this.locked,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool locked;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final enabled = onTap != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: locked ? '$label. Premium' : label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? c.accent : c.accent.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: c.onAccent,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (locked) ...[
                      Icon(Icons.lock_rounded, size: 18, color: c.onAccent),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: AppTypography.title(
                        17,
                        c.onAccent,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
