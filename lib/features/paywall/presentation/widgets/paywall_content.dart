import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../exercises/data/exercise_catalog.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../exercises/presentation/widgets/exercise_picture.dart';
import '../../../plans/data/plan_templates.dart';
import '../../data/subscription_service.dart';
import '../../domain/paywall_offer.dart';
import '../../domain/subscription.dart';
import '../providers/subscription_providers.dart';
import '../../../../core/haptics/haptics.dart';

const _pinkA = Color(0xFFFF7E98);
const _pinkB = Color(0xFFEF5B82);

/// Exercises whose thumbnails orbit the photo: pull, push, core, legs,
/// handstand, so the ring shows the whole library at a glance.
const _orbitExercises = [37, 60, 66, 73, 13, 19, 21, 48];

/// The paywall (route `/paywall` and the onboarding step), on one screen:
/// the photo inside a turning ring of exercise thumbnails, three wins, a
/// Monthly | Yearly switch, the price and the buy button.
///
/// [onClose] is the X and "Not now": the user keeps the free tier (one
/// plan). After a purchase a short "welcome" screen shows, then [onClose]
/// runs too.
class PaywallContent extends ConsumerStatefulWidget {
  const PaywallContent({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<PaywallContent> createState() => _PaywallContentState();
}

class _PaywallContentState extends ConsumerState<PaywallContent> {
  PremiumPlan _choice = PremiumPlan.monthly;
  bool _busy = false;
  SubscriptionStatus? _bought;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy() async {
    if (_busy) return;
    Haptics.medium();
    setState(() => _busy = true);
    try {
      final s = await ref.read(subscriptionProvider.notifier).purchase(_choice);
      if (!mounted) return;
      Haptics.heavy();
      setState(() => _bought = s);
    } on PurchaseFailure catch (e) {
      if (mounted && !e.cancelled) _say(e.message);
    } catch (e) {
      if (mounted) _say('The purchase did not go through. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final s = await ref.read(subscriptionProvider.notifier).restore();
      if (!mounted) return;
      if (s.isPremium) {
        setState(() => _bought = s);
      } else {
        _say('No active subscription was found.');
      }
    } catch (_) {
      if (mounted) _say('Could not restore purchases. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final offers =
        ref.watch(paywallOffersProvider).asData?.value ?? defaultPaywallOffers;
    final current = ref.watch(subscriptionProvider);
    PaywallOffer offerFor(PremiumPlan p) =>
        offers.where((o) => o.plan == p).firstOrNull ??
        defaultPaywallOffers.firstWhere((o) => o.plan == p);
    final chosen = offerFor(_choice);
    final trial = current.isPremium ? null : chosen.trialDays;

    final cta = current.plan == _choice
        ? 'Your current plan'
        : trial != null
        ? 'Start my free trial'
        : 'Continue · ${chosen.price}/${chosen.period}';
    final hint = trial != null
        ? '$trial days free, then ${chosen.price}/${chosen.period}'
        : chosen.perMonth != null
        ? 'Only ${chosen.perMonth} a month'
        : 'Billed every ${chosen.period}';

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final heroH = (box.maxHeight * 0.47).clamp(240.0, 400.0);
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _OrbitHero(height: heroH, onClose: widget.onClose),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          children: [
                            Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                style: AppTypography.title(
                                  25,
                                  c.textPrimary,
                                  weight: FontWeight.w600,
                                  height: 1.15,
                                ),
                                children: [
                                  const TextSpan(text: 'Unlock your full '),
                                  TextSpan(
                                    text: 'journey',
                                    style: AppTypography.accentSerif(
                                      c.accentText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final (i, label) in [
                                  'All ${planTemplates.length} plans',
                                  '${exerciseCatalog.length} exercises',
                                  'Video coaching',
                                ].indexed)
                                  _Pop(
                                    delay: Duration(
                                      milliseconds: 300 + 120 * i,
                                    ),
                                    child: _Chip(label: label),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _PlanToggle(
                              value: _choice,
                              yearlyTag: 'Save 58%',
                              onChanged: (p) {
                                Haptics.light();
                                setState(() => _choice = p);
                              },
                            ),
                            const SizedBox(height: 14),
                            _Price(
                              price: chosen.price,
                              period: chosen.period,
                              hint: hint,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                        child: Column(
                          children: [
                            RepaintBoundary(
                              child: _BuyButton(
                                label: cta,
                                busy: _busy,
                                onTap: current.plan == _choice ? null : _buy,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              (kReleaseMode ||
                                      ref
                                          .read(subscriptionServiceProvider)
                                          .isLive)
                                  ? 'Renews automatically until you cancel in your store settings.'
                                  : 'Test mode: no payment is taken.',
                              textAlign: TextAlign.center,
                              style: AppTypography.body(
                                c.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                _LinkButton(
                                  label: 'Not now',
                                  onTap: widget.onClose,
                                ),
                                _LinkButton(label: 'Restore', onTap: _restore),
                                _LinkButton(
                                  label: 'Terms',
                                  onTap: () => context.push('/terms'),
                                ),
                                _LinkButton(
                                  label: 'Privacy',
                                  onTap: () => context.push('/privacy'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_bought != null)
          Positioned.fill(
            child: _Welcome(status: _bought!, onDone: widget.onClose),
          ),
      ],
    );
  }
}

/// The photo on a rose glow, inside a slowly turning dashed ring that
/// carries exercise thumbnails; each thumbnail gently zooms in and out.
class _OrbitHero extends StatefulWidget {
  const _OrbitHero({required this.height, required this.onClose});

  final double height;
  final VoidCallback onClose;

  @override
  State<_OrbitHero> createState() => _OrbitHeroState();
}

class _OrbitHeroState extends State<_OrbitHero>
    with SingleTickerProviderStateMixin {
  static const _turnSeconds = 40.0;
  static const _pulseSeconds = 2.8;

  /// Seconds since the orbit started, updated about 30 times a second: the
  /// ring turns so slowly that 60 fps would only double the drawing work.
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker((elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    if (t - _time.value >= 0.032) _time.value = t;
  });

  /// 0 to 1: one full turn of the ring.
  double get _turnValue => (_time.value / _turnSeconds) % 1;

  /// 0 to 1: one beat of the zoom in and out.
  double get _pulseValue => (_time.value / _pulseSeconds) % 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final h = widget.height;
    return SizedBox(
      height: h,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          const thumb = 46.0;
          // An oval around her, wide enough that the thumbnails on its
          // sides clear her arms, and short enough to stay above the title.
          final radius = Size(w / 2 - thumb / 2 - 12, h / 2 - thumb / 2 - 8);
          final center = Offset(w / 2, h / 2 + 6);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.1,
                      colors: [c.softRose, c.background],
                      stops: const [0, 0.75],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _time,
                    builder: (context, _) => CustomPaint(
                      painter: _DashedRing(
                        center: center,
                        radius: radius,
                        turn: _turnValue,
                        color: c.accent.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
              // Thumbnails ride the ring (behind the photo). Their own layer,
              // so the animation never repaints the rest of the page.
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _time,
                  builder: (context, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < _orbitExercises.length; i++)
                        _orbitThumb(i, center, radius, thumb),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: h * 0.9,
                child: RepaintBoundary(
                  child: _Rise(
                    // The photo fades into the page at the bottom with a plain
                    // gradient in the page colour (a mask would force an extra
                    // full-size drawing pass on every frame).
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const BunnyImage(
                          'onboarding/your-plan/after',
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -1,
                          height: h * 0.2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  c.background.withValues(alpha: 0),
                                  c.background,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 14,
                child: Semantics(
                  button: true,
                  label: 'Close',
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.surface.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orbitThumb(int i, Offset center, Size radius, double size) {
    final n = _orbitExercises.length;
    final a = 2 * math.pi * (i / n + _turnValue) - math.pi / 2;
    // Each one breathes on its own beat, so they twinkle around the ring.
    final beat = math.sin(2 * math.pi * (_pulseValue + i / n));
    return Positioned(
      left: center.dx + radius.width * math.cos(a) - size / 2,
      top: center.dy + radius.height * math.sin(a) - size / 2,
      child: Transform.scale(
        scale: 0.9 + 0.12 * beat,
        // The thumbnail itself never changes, so it is drawn once and only
        // moved and scaled afterwards.
        child: RepaintBoundary(child: _thumbs[i]),
      ),
    );
  }

  late final List<Widget> _thumbs = [
    for (final n in _orbitExercises) _OrbitThumb(number: n, size: 46),
  ];
}

class _OrbitThumb extends StatelessWidget {
  const _OrbitThumb({required this.number, required this.size});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.surface,
        // A rose ring instead of a blurred shadow: blurs are costly to redraw
        // on every frame of the orbit on modest phones.
        border: Border.all(color: c.surface, width: 3),
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _pinkB.withValues(alpha: 0.35), width: 1),
      ),
      child: ClipOval(
        child: ExercisePicture(
          exercise: exerciseByNumber(number),
          compact: true,
          cacheWidth: 160,
        ),
      ),
    );
  }
}

class _DashedRing extends CustomPainter {
  _DashedRing({
    required this.center,
    required this.radius,
    required this.turn,
    required this.color,
  });

  final Offset center;
  final Size radius;
  final double turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashes = 64;
    const sweep = 2 * math.pi / dashes;
    final rect = Rect.fromCenter(
      center: center,
      width: radius.width * 2,
      height: radius.height * 2,
    );
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        rect,
        2 * math.pi * turn + i * sweep,
        sweep * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) =>
      old.turn != turn || old.radius != radius || old.color != color;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 11, 5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Tick(size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.title(
              12,
              c.textPrimary,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pinkA, _pinkB],
        ),
      ),
      child: Icon(Icons.check_rounded, size: size * 0.62, color: Colors.white),
    );
  }
}

/// Monthly | Yearly, with a gradient thumb that slides to the choice.
class _PlanToggle extends StatelessWidget {
  const _PlanToggle({
    required this.value,
    required this.onChanged,
    required this.yearlyTag,
  });

  final PremiumPlan value;
  final ValueChanged<PremiumPlan> onChanged;
  final String yearlyTag;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final yearly = value == PremiumPlan.yearly;
    Widget option(PremiumPlan p, String label, String? tag) {
      final on = value == p;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: tag == null ? label : '$label, $tag',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(p),
            child: SizedBox(
              height: 42,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: AppTypography.title(
                        14.5,
                        on ? Colors.white : c.textSecondary,
                        weight: FontWeight.w600,
                      ),
                      child: Text(label),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 5),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: on
                              ? Colors.white.withValues(alpha: 0.25)
                              : c.softRose,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          tag,
                          style: AppTypography.title(
                            9.5,
                            on ? Colors.white : c.accentText,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.divider, width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              alignment: yearly ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: const LinearGradient(colors: [_pinkA, _pinkB]),
                    boxShadow: [
                      BoxShadow(
                        color: _pinkB.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              option(PremiumPlan.monthly, 'Monthly', null),
              option(PremiumPlan.yearly, 'Yearly', yearlyTag),
            ],
          ),
        ],
      ),
    );
  }
}

/// The big price with its period and a short line under it.
class _Price extends StatelessWidget {
  const _Price({required this.price, required this.period, required this.hint});

  final String price;
  final String period;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(price),
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: price,
                  style: AppTypography.title(
                    34,
                    c.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '  / $period',
                  style: AppTypography.body(c.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: AppTypography.title(
              12.5,
              c.accentText,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// The gradient buy button with a passing shine and a spinner while busy.
class _BuyButton extends StatefulWidget {
  const _BuyButton({required this.label, required this.busy, this.onTap});

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton>
    with SingleTickerProviderStateMixin {
  /// One sweep of light, about 0.9 s. It runs every few seconds and rests
  /// in between, so a waiting screen draws nothing most of the time.
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _every;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _every?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) return;
    _every = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (mounted) _shine.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _every?.cancel();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.busy;
    final c = context.appColors;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.onTap == null ? 0.55 : 1,
          child: Container(
            height: 58,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(colors: [_pinkA, _pinkB, c.accent]),
              boxShadow: [
                BoxShadow(
                  color: _pinkB.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (enabled)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shine,
                      builder: (context, _) {
                        final t = _shine.value;
                        return FractionalTranslation(
                          translation: Offset(-1 + 2 * t, 0),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x00FFFFFF),
                                  Color(0x55FFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                                stops: [0.3, 0.5, 0.7],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                widget.busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: AppTypography.title(
                          17,
                          Colors.white,
                          weight: FontWeight.w600,
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

/// After buying: a big tick, falling confetti and what is unlocked now.
class _Welcome extends StatefulWidget {
  const _Welcome({required this.status, required this.onDone});

  final SubscriptionStatus status;
  final VoidCallback onDone;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  final _confetti = List.generate(36, (i) => math.Random(i));

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = widget.status;
    final trial = s.inTrial;
    final days = s.trialDaysLeft(DateTime.now());
    final colors = [
      _pinkA,
      _pinkB,
      c.softRose,
      const Color(0xFFFFD27A),
      c.accent,
    ];
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final t = _a.value;
        final pop = Curves.elasticOut.transform((t / 0.45).clamp(0.0, 1.0));
        return Opacity(
          opacity: (t / 0.12).clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.25),
                radius: 0.9,
                colors: [c.softRose, c.background],
              ),
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      for (final (i, r) in _confetti.indexed)
                        Positioned(
                          left: box.maxWidth * ((i * 37 % 100) / 100),
                          top:
                              -20 +
                              (box.maxHeight + 40) *
                                  Curves.easeIn.transform(
                                    ((t - (i % 6) * 0.04) *
                                            (1.1 + (i % 4) * 0.12))
                                        .clamp(0.0, 1.0),
                                  ),
                          child: Transform.rotate(
                            angle: t * 9 * (i.isEven ? 1 : -1) + r.nextDouble(),
                            child: Container(
                              width: 8,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: pop,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_pinkA, _pinkB],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _pinkB.withValues(alpha: 0.35),
                                  blurRadius: 40,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 58,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            style: AppTypography.title(
                              26,
                              c.textPrimary,
                              weight: FontWeight.w600,
                            ),
                            children: trial
                                ? [
                                    const TextSpan(text: 'Your free trial '),
                                    TextSpan(
                                      text: 'has started',
                                      style: AppTypography.accentSerif(
                                        c.accentText,
                                      ),
                                    ),
                                  ]
                                : [
                                    const TextSpan(text: 'Welcome to '),
                                    TextSpan(
                                      text: 'Premium',
                                      style: AppTypography.accentSerif(
                                        c.accentText,
                                      ),
                                    ),
                                  ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          trial
                              ? 'Every plan and all ${exerciseCatalog.length} '
                                    'exercises are unlocked. Your trial ends '
                                    'in $days days.'
                              : 'Every plan and all ${exerciseCatalog.length} '
                                    'exercises are unlocked.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            c.textSecondary,
                            fontSize: 14.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _BuyButton(
                          label: "Let's train",
                          busy: false,
                          onTap: widget.onDone,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 36),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTypography.body(
          context.appColors.textSecondary,
          fontSize: 12.5,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Rises in from below on first show.
class _Rise extends StatelessWidget {
  const _Rise({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// Fades and pops in after [delay].
class _Pop extends StatelessWidget {
  const _Pop({required this.child, required this.delay});
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = delay + const Duration(milliseconds: 550);
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      child: child,
      builder: (context, v, child) {
        final t = ((v - start) / (1 - start)).clamp(0.0, 1.0);
        final curved = Curves.easeOutBack.transform(t);
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.6 + 0.4 * curved, child: child),
        );
      },
    );
  }
}
