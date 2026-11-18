import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';

/// One published source behind the app's training guidance.
class TrainingSource {
  const TrainingSource({
    required this.title,
    required this.publisher,
    required this.url,
    required this.usedFor,
  });

  final String title;
  final String publisher;
  final String url;

  /// What in the app follows this source.
  final String usedFor;
}

/// The guidelines the plans and safety advice follow (App Store Review
/// Guideline 1.4.1: health and fitness guidance cites its sources, easy to
/// find in the app). Every link is a public guideline or peer-reviewed paper.
const trainingSources = [
  TrainingSource(
    title: 'WHO guidelines on physical activity and sedentary behaviour (2020)',
    publisher: 'World Health Organization',
    url: 'https://www.who.int/publications/i/item/9789240015128',
    usedFor:
        'Weekly training days and muscle-strengthening on 2 or more days a '
        'week.',
  ),
  TrainingSource(
    title:
        'Progression models in resistance training for healthy adults '
        '(Position Stand, 2009)',
    publisher: 'American College of Sports Medicine',
    url: 'https://doi.org/10.1249/MSS.0b013e3181915670',
    usedFor:
        'Sets, repetitions, rest between sets, and moving from easier to '
        'harder versions of an exercise.',
  ),
  TrainingSource(
    title:
        'Quantity and quality of exercise for developing and maintaining '
        'cardiorespiratory, musculoskeletal, and neuromotor fitness in '
        'apparently healthy adults (Position Stand, 2011)',
    publisher: 'American College of Sports Medicine',
    url: 'https://doi.org/10.1249/MSS.0b013e318213fefb',
    usedFor:
        'Warm-up and cool-down in every workout, gradual progression, and '
        'session length.',
  ),
  TrainingSource(
    title:
        'Physical activity and exercise during pregnancy and the postpartum '
        'period (Committee Opinion No. 804, 2020)',
    publisher: 'American College of Obstetricians and Gynecologists',
    url: 'https://doi.org/10.1097/AOG.0000000000003772',
    usedFor:
        'The advice to talk to a doctor before training while pregnant or '
        'after giving birth.',
  ),
  TrainingSource(
    title:
        'World Health Organization 2020 guidelines on physical activity and '
        'sedentary behaviour (summary paper)',
    publisher: 'British Journal of Sports Medicine',
    url: 'https://doi.org/10.1136/bjsports-2020-102955',
    usedFor: 'The evidence summary behind the WHO recommendations above.',
  ),
];

/// "Sources & methodology": how the plans are built and the published
/// guidelines they follow, each with a link.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  static const _method = [
    'Your plan is built by fixed rules from your answers (days per week, '
        'session length, experience, equipment and focus). There is no '
        'medical assessment and nothing is diagnosed.',
    'Every workout starts with a warm-up and ends with a cool-down. Sets, '
        'repetitions and rest times follow the resistance-training '
        'guidelines listed below.',
    'After each exercise you rate how it felt (Easy, Just right, Hard). '
        'The next sessions are adjusted from those ratings and from your '
        'plank test, so the work grows step by step.',
    '"Areas to protect" only swap out exercises that load that area. They '
        'are your own preference, not an injury assessment.',
    'This app is training guidance, not medical advice. Talk to a doctor '
        'before you start if you are pregnant, injured or managing a medical '
        'condition, and stop if anything hurts.',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      'Sources & methodology',
                      style: AppTypography.title(
                        20,
                        c.textPrimary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  _Heading('How your plan is built', c.textPrimary),
                  for (final p in _method)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        p,
                        style: AppTypography.body(
                          c.textSecondary,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _Heading('Sources', c.textPrimary),
                  for (final s in trainingSources) _SourceCard(source: s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: AppTypography.title(17, color, weight: FontWeight.w600),
    ),
  );
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});
  final TrainingSource source;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => launchUrl(
            Uri.parse(source.url),
            mode: LaunchMode.externalApplication,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  style: AppTypography.body(
                    c.textPrimary,
                    fontSize: 14.5,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  source.publisher,
                  style: AppTypography.body(c.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Used for: ${source.usedFor}',
                  style: AppTypography.body(c.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: c.accentText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        source.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(c.accentText, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
