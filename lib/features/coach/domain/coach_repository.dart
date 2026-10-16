import 'coach_message.dart';

/// Thrown when no AI backend is connected (or it can't be reached).
class CoachUnavailable implements Exception {
  const CoachUnavailable([this.reason = "Coach isn't connected yet"]);
  final String reason;
  @override
  String toString() => 'CoachUnavailable: $reason';
}

/// Where Coach replies come from. The planned backend is the `coachChat`
/// Cloud Function; no provider is chosen or integrated yet.
abstract interface class CoachRepository {
  /// False when replies cannot be produced, so the UI can say so up front.
  bool get isAvailable;

  /// Reply to [text] given the earlier [history]. Throws [CoachUnavailable].
  Future<String> send(List<CoachMessage> history, String text);
}

/// Default until the backend exists. Never invents a reply.
class UnavailableCoachRepository implements CoachRepository {
  const UnavailableCoachRepository();

  @override
  bool get isAvailable => false;

  @override
  Future<String> send(List<CoachMessage> history, String text) =>
      Future.error(const CoachUnavailable());
}
