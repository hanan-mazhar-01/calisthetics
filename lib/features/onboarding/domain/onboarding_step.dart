/// A headline split into three parts so the middle segment can be rendered
/// in the brand accent color, e.g. ['How ', 'old', ' are you?'].
class Headline {
  const Headline(this.lead, this.accent, [this.tail = '']);

  final String lead;
  final String accent;
  final String tail;
}

enum ChoiceLayout { list, grid, slider }

enum ChoiceSelection { single, multi }

class ChoiceOption {
  const ChoiceOption({
    required this.id,
    required this.label,
    this.description,
    this.imagePrompt,
    this.glyph,
    this.feedbackLead,
    this.feedbackBody,
  });

  /// Stable, persisted identifier. Selections are stored by id, never by list
  /// position, so reordering or inserting options can't corrupt saved answers.
  final String id;
  final String label;
  final String? description;

  /// Asset brief for the photo tile (grid layout) — mirrors the design's
  /// `<image-slot placeholder="...">` text until a real asset is wired in.
  final String? imagePrompt;

  /// Short text/letter badge shown instead of a photo (list layout, no image).
  final String? glyph;

  /// Bold lead-in shown inline once this option is selected (self-assessment
  /// screens like Endurance/Squat test), e.g. "Good to know." followed by
  /// [feedbackBody]'s full sentence. Null when the option has no feedback.
  final String? feedbackLead;
  final String? feedbackBody;
}

/// One step in the onboarding flow. Sealed so the presentation layer can
/// exhaustively switch over step shape without a runtime type tag.
sealed class OnboardingStep {
  const OnboardingStep({required this.id, this.chapter});

  final String id;

  /// 1-4, null for non-chapter screens (welcome, part intros have their own chapter).
  final int? chapter;

  /// Sticky back+progress header. Hidden on welcome and chapter-divider screens.
  bool get showsChrome => false;

  /// Persistent bottom "Continue"-style CTA. Single-select choice steps
  /// auto-advance instead, so they don't need one.
  bool get showsContinueCta => false;
}

class WelcomeStep extends OnboardingStep {
  const WelcomeStep({required super.id});
}

class PartIntroStep extends OnboardingStep {
  const PartIntroStep({
    required super.id,
    required super.chapter,
    required this.chapterNumberLabel,
    required this.headline,
    required this.subtitle,
    required this.ctaLabel,
  });

  final String chapterNumberLabel;
  final Headline headline;
  final String subtitle;
  final String ctaLabel;

  @override
  bool get showsContinueCta => true;
}

class ChoiceStep extends OnboardingStep {
  const ChoiceStep({
    required super.id,
    required super.chapter,
    required this.headline,
    this.subtitle,
    required this.layout,
    required this.selection,
    this.autoAdvance = true,
    required this.options,
    this.gridColumns = 2,
    this.gridAspectRatio = 0.82,
    this.exclusiveOptionId,
    this.optional = false,
  });

  final Headline headline;
  final String? subtitle;
  final ChoiceLayout layout;
  final ChoiceSelection selection;
  final bool autoAdvance;
  final List<ChoiceOption> options;

  /// Only used when [layout] is [ChoiceLayout.grid]. Aspect ratio (not a
  /// fixed pixel height) so tiles stay proportional across phone sizes.
  final int gridColumns;
  final double gridAspectRatio;

  /// Multi-select only: id of an option (e.g. "None") that excludes all the
  /// others. Choosing it clears the rest; choosing any other clears it.
  final String? exclusiveOptionId;

  /// When true the step can be continued with nothing selected.
  final bool optional;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => !autoAdvance;
}

class CurvePoint {
  const CurvePoint({
    required this.xFraction,
    required this.yFraction,
    required this.label,
    this.emphasized = false,
  });

  /// 0-1 position along the chart width/height (mirrors the design's % values).
  final double xFraction;
  final double yFraction;
  final String label;
  final bool emphasized;
}

/// Free-text first-name capture.
class NameStep extends OnboardingStep {
  const NameStep({
    required super.id,
    required super.chapter,
    required this.headline,
  });

  final Headline headline;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}

/// Full-bleed dark reassurance screen, no options — just a beat to let a
/// milestone land before moving on. `{name}` in [headline] is substituted
/// with the captured first name at render time.
class WinStep extends OnboardingStep {
  const WinStep({
    required super.id,
    required super.chapter,
    required this.headline,
    required this.subtitle,
  });

  final Headline headline;
  final String subtitle;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}

/// Live plank-hold timer with a circular progress ring.
class PlankStep extends OnboardingStep {
  const PlankStep({
    required super.id,
    required super.chapter,
    required this.headline,
    required this.subtitle,
  });

  final Headline headline;
  final String subtitle;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}

/// Two-column "old way vs the Calesthetics way" comparison panel.
class CompareStep extends OnboardingStep {
  const CompareStep({
    required super.id,
    required super.chapter,
    required this.headline,
    required this.leftItems,
    required this.rightItems,
  });

  final Headline headline;
  final List<String> leftItems;
  final List<String> rightItems;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}

class Milestone {
  const Milestone({
    required this.week,
    required this.label,
    required this.description,
  });
  final String week;
  final String label;
  final String description;
}

/// Vertical milestone timeline, each entry revealing with a stagger.
class MilestonesStep extends OnboardingStep {
  const MilestonesStep({
    required super.id,
    required super.chapter,
    required this.headline,
    required this.milestones,
  });

  final Headline headline;
  final List<Milestone> milestones;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}

class FocusArea {
  const FocusArea({
    required this.id,
    required this.label,
    required this.xFraction,
    required this.yFraction,
  });
  final String id;
  final String label;
  final double xFraction;
  final double yFraction;
}

/// Body-silhouette multi-select (muscle-focus areas). Pill positions are
/// fractional over the silhouette so they scale with any screen width.
class FocusStep extends OnboardingStep {
  const FocusStep({
    required super.id,
    required super.chapter,
    required this.headline,
    required this.areas,
  });

  final Headline headline;
  final List<FocusArea> areas;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}

/// Emotional-benefit screen: two contrasted photo panels + a paragraph.
class PairStep extends OnboardingStep {
  const PairStep({
    required super.id,
    required super.chapter,
    required this.headline,
  });

  final Headline headline;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}

/// Full-bleed photo with an overlaid rhetorical question ("Story ·" screens).
class PhotoQuestionStep extends OnboardingStep {
  const PhotoQuestionStep({
    required super.id,
    required super.chapter,
    required this.question,
    required this.photoPrompt,
  });

  final String question;
  final String photoPrompt;
}

/// Plan-selection screen. Its content (the "best for you" hero and the
/// "or explore" list) comes from `PlanRecommender` at render time.
class PlansStep extends OnboardingStep {
  const PlansStep({
    required super.id,
    required super.chapter,
    required this.headline,
    this.subtitle,
  });

  final Headline headline;
  final String? subtitle;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}

/// Animated "building your plan" progress screen.
class LoadingStep extends OnboardingStep {
  const LoadingStep({
    required super.id,
    required this.stages,
    this.previewExercises = const [],
  });

  final List<String> stages;

  /// Names of exercises from the plan being built, shown while it loads.
  final List<String> previewExercises;
}

class PlanStat {
  const PlanStat({required this.value, required this.label});
  final String value;
  final String label;
}

/// Dark staged reveal of the generated plan's headline stats.
class RevealStep extends OnboardingStep {
  const RevealStep({
    required super.id,
    required this.ctaLabel,
    required this.stats,
  });

  final String ctaLabel;
  final List<PlanStat> stats;

  @override
  bool get showsContinueCta => true;
}

class PlanRow {
  const PlanRow({required this.key, required this.value});
  final String key;
  final String value;
}

class MuscleAllocation {
  const MuscleAllocation({required this.label, required this.fraction});
  final String label;
  final double fraction;
}

class CalendarDay {
  const CalendarDay({required this.label, required this.isTraining});
  final String label;
  final bool isTraining;
}

/// "What's inside" plan summary: key/value rows + muscle-group bars.
class PlanContentStep extends OnboardingStep {
  const PlanContentStep({
    required super.id,
    required this.headline,
    required this.rows,
    required this.muscleAllocations,
    required this.ctaLabel,
    this.calendar = const [],
    this.calendarNote,
  });

  final Headline headline;
  final List<PlanRow> rows;
  final List<MuscleAllocation> muscleAllocations;

  /// The first week laid out by weekday (Mon-Sun), training days marked.
  final List<CalendarDay> calendar;
  final String? calendarNote;
  final String ctaLabel;

  @override
  bool get showsContinueCta => true;
}

class ProgramPhase {
  const ProgramPhase({
    required this.number,
    required this.label,
    required this.weekRange,
    this.exercises = const [],
    this.sessionName = '',
    this.exerciseNumbers = const [],
    this.targets = const [],
  });
  final String number;
  final String label;
  final String weekRange;

  /// Exercise names from that phase's first session.
  final List<String> exercises;

  /// Name of the session shown for the phase (e.g. "Upper body & core").
  final String sessionName;

  /// Catalog numbers of [exercises], same order (for thumbnails).
  final List<int> exerciseNumbers;

  /// Short target per exercise, same order: `20s` for holds, `x8` for reps.
  final List<String> targets;
}

/// "Four phases" plan preview: each phase's exercise thumbnails.
class PlanPreviewStep extends OnboardingStep {
  const PlanPreviewStep({
    required super.id,
    required this.headline,
    required this.phases,
    required this.ctaLabel,
  });

  final Headline headline;
  final List<ProgramPhase> phases;
  final String ctaLabel;

  @override
  bool get showsContinueCta => true;
}

/// The paywall: free-vs-premium on one screen. Offers come from
/// `paywallOffersProvider`; the step only decides where it sits in the flow.
class PaywallStep extends OnboardingStep {
  const PaywallStep({required super.id});
}

/// Optional account creation (Apple / Google / email) with a visible Skip.
class AccountStep extends OnboardingStep {
  const AccountStep({required super.id});
}

/// Health note: she acknowledges that this is not medical advice.
class HealthNoteStep extends OnboardingStep {
  const HealthNoteStep({
    required super.id,
    required super.chapter,
    required this.headline,
    required this.subtitle,
  });

  final Headline headline;
  final String subtitle;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}

class MosaicTile {
  const MosaicTile({
    required this.label,
    required this.photoPrompt,
    required this.height,
  });
  final String label;
  final String photoPrompt;
  final double height;
}

/// Asymmetric photo mosaic ("Train anywhere", "Exercise library" — the
/// latter ends onboarding and enters the main app).
class MosaicStep extends OnboardingStep {
  const MosaicStep({
    required super.id,
    required this.headline,
    required this.tiles,
    required this.ctaLabel,
  });

  final Headline headline;
  final List<MosaicTile> tiles;
  final String ctaLabel;

  @override
  bool get showsContinueCta => true;
}

class CurveStep extends OnboardingStep {
  const CurveStep({
    required super.id,
    required super.chapter,
    required this.headline,
    required this.xAxisLabels,
    required this.points,
    required this.footer,
    this.ctaLabel = 'Continue',
  });

  final Headline headline;
  final List<String> xAxisLabels;
  final List<CurvePoint> points;
  final String footer;
  final String ctaLabel;

  @override
  bool get showsChrome => true;

  @override
  bool get showsContinueCta => true;
}
