import '../../plans/domain/plan_builder.dart';

/// What the workout player is asked to run: one built session of a plan
/// ([templateId] is the plan template's id).
class WorkoutRequest {
  const WorkoutRequest({
    required this.templateId,
    required this.session,
    this.progressKey,
    this.demo = false,
  });

  /// A 30-second try-out of one exercise from Discover: the same player, but
  /// it starts straight away, asks for no rating, saves nothing and closes
  /// when the time is up.
  factory WorkoutRequest.demo(int exerciseNumber, String name) =>
      WorkoutRequest(
        templateId: 'demo',
        demo: true,
        session: BuiltSession(
          name: name,
          warmUp: const [],
          items: [
            BuiltItem(
              exerciseNumber: exerciseNumber,
              sets: 1,
              holdSeconds: demoSeconds,
            ),
          ],
          coolDown: const [],
          estimatedMinutes: 1,
        ),
      );

  static const demoSeconds = 30;

  final bool demo;

  final String templateId;
  final BuiltSession session;

  /// Day id (see `dayProgressKey`) under which quitting early saves how far
  /// she got; null for ad-hoc sessions.
  final String? progressKey;
}
