import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plan/presentation/providers/plan_providers.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/coach_message.dart';
import '../../domain/coach_quota.dart';
import '../../domain/coach_repository.dart';

/// Swap this override when the `coachChat` backend is integrated.
final coachRepositoryProvider = Provider<CoachRepository>(
  (ref) => const UnavailableCoachRepository(),
);

class CoachState {
  const CoachState({
    this.messages = const [],
    this.typing = false,
    this.unavailable = false,
  });

  final List<CoachMessage> messages;
  final bool typing;

  /// Set when the repository says it can't answer.
  final bool unavailable;

  CoachState copyWith({
    List<CoachMessage>? messages,
    bool? typing,
    bool? unavailable,
  }) => CoachState(
    messages: messages ?? this.messages,
    typing: typing ?? this.typing,
    unavailable: unavailable ?? this.unavailable,
  );
}

final coachControllerProvider =
    NotifierProvider.autoDispose<CoachController, CoachState>(
      CoachController.new,
    );

/// Current month's quota, derived from settings.
final coachQuotaProvider = Provider.autoDispose<CoachQuota>((ref) {
  final now = ref.watch(clockProvider)();
  return CoachQuota.fromJson(ref.watch(settingsProvider)['coachUsage'], now);
});

class CoachController extends Notifier<CoachState> {
  @override
  CoachState build() =>
      CoachState(unavailable: !ref.read(coachRepositoryProvider).isAvailable);

  bool get canSend {
    if (state.unavailable || state.typing) return false;
    final now = ref.read(clockProvider)();
    return ref
        .read(coachQuotaProvider)
        .canSend(now, isPremium: ref.read(isPremiumProvider));
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || !canSend) return;
    final history = state.messages;
    state = state.copyWith(
      messages: [...history, CoachMessage(CoachRole.user, text)],
      typing: true,
    );
    try {
      final reply = await ref.read(coachRepositoryProvider).send(history, text);
      final now = ref.read(clockProvider)();
      await ref
          .read(settingsProvider.notifier)
          .set(
            'coachUsage',
            ref.read(coachQuotaProvider).recordSend(now).toJson(),
          );
      state = state.copyWith(
        messages: [...state.messages, CoachMessage(CoachRole.coach, reply)],
        typing: false,
      );
    } on CoachUnavailable {
      // Drop the unanswered message: nothing was sent, nothing is counted.
      state = state.copyWith(
        messages: history,
        typing: false,
        unavailable: true,
      );
    }
  }
}
