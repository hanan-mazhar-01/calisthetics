import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/app_background.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../plan/presentation/providers/plan_providers.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/coach_message.dart';
import '../../domain/coach_quota.dart';
import '../../domain/coach_suggestions.dart';
import '../providers/coach_providers.dart';

const _disclaimer =
    'Coach shares general training tips, not medical advice. '
    'For pain or health concerns, speak to a qualified professional.';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    _input.clear();
    final future = ref.read(coachControllerProvider.notifier).send(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final state = ref.watch(coachControllerProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final now = ref.watch(clockProvider)();
    final quota = ref.watch(coachQuotaProvider);
    final remaining = quota.remaining(now);
    final limitReached = !isPremium && remaining == 0;
    final disabled = state.unavailable || limitReached;
    final starters = coachStarters(ref.watch(activeTemplateProvider));

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Coach',
                      style: AppTypography.title(
                        28,
                        c.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!isPremium) _QuotaChip(remaining: remaining),
                ],
              ),
            ),
            Expanded(
              child: state.messages.isEmpty
                  ? _Empty(
                      unavailable: state.unavailable,
                      starters: starters,
                      enabled: !disabled,
                      onPick: _send,
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: state.messages.length + (state.typing ? 1 : 0),
                      itemBuilder: (_, i) => i == state.messages.length
                          ? const _TypingIndicator()
                          : _Bubble(message: state.messages[i]),
                    ),
            ),
            if (limitReached)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GlassCard(
                  onTap: () => context.push('/paywall'),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: c.accentText),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "You've used your $freeMonthlyCoachMessages free messages this month. Upgrade to keep chatting.",
                          style: AppTypography.body(
                            c.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: c.textMuted),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                _disclaimer,
                textAlign: TextAlign.center,
                style: AppTypography.body(c.textMuted, fontSize: 11),
              ),
            ),
            _InputBar(
              controller: _input,
              enabled: !disabled && !state.typing,
              hint: state.unavailable
                  ? "Coach isn't connected yet"
                  : (limitReached
                        ? 'Message limit reached'
                        : 'Ask about your training'),
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaChip extends StatelessWidget {
  const _QuotaChip({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.divider),
      ),
      child: Text(
        '$remaining of $freeMonthlyCoachMessages free left',
        style: AppTypography.body(
          c.textSecondary,
          fontSize: 12,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.unavailable,
    required this.starters,
    required this.enabled,
    required this.onPick,
  });
  final bool unavailable;
  final List<String> starters;
  final bool enabled;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      children: [
        if (unavailable)
          GlassCard(
            child: Row(
              children: [
                Icon(Icons.cloud_off_outlined, color: c.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Coach isn't connected yet. Check back in a future update.",
                    style: AppTypography.body(c.textPrimary, fontSize: 14),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'Ask me anything about your training.',
            style: AppTypography.body(c.textSecondary),
          ),
        const SizedBox(height: 16),
        Text('TRY ASKING', style: AppTypography.kicker(c.textMuted)),
        const SizedBox(height: 8),
        for (final s in starters)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: GlassCard(
                onTap: enabled ? () => onPick(s) : null,
                child: Text(
                  s,
                  style: AppTypography.body(c.textPrimary, fontSize: 14),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final mine = message.role == CoachRole.user;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: mine ? c.accent : c.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: AppTypography.body(
            mine ? c.onAccent : c.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        label: 'Coach is typing',
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedBuilder(
            animation: _ctl,
            builder: (_, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.textMuted.withValues(
                        alpha:
                            0.35 +
                            0.65 * ((_ctl.value * 3 - i) % 3 < 1 ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              style: AppTypography.body(c.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.body(c.textMuted),
                filled: true,
                fillColor: c.surface.withValues(alpha: enabled ? 0.8 : 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: c.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: c.divider),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: c.divider),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
            ),
            tooltip: 'Send',
            onPressed: enabled ? () => onSend(controller.text) : null,
            icon: const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }
}
