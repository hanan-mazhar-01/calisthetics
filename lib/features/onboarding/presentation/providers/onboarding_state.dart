import 'package:flutter/foundation.dart';

@immutable
class OnboardingState {
  const OnboardingState({
    required this.index,
    required this.selections,
    this.name = '',
    this.plankSeconds,
  });

  final int index;
  final Map<String, Set<String>> selections;

  /// Free-text first name captured on the Name step; interpolated into
  /// later copy (`{name}`) on win/encouragement screens.
  final String name;

  /// Whole seconds held in the plank test, or null until she takes it.
  final int? plankSeconds;

  OnboardingState copyWith({
    int? index,
    Map<String, Set<String>>? selections,
    String? name,
    int? plankSeconds,
  }) {
    return OnboardingState(
      index: index ?? this.index,
      selections: selections ?? this.selections,
      name: name ?? this.name,
      plankSeconds: plankSeconds ?? this.plankSeconds,
    );
  }
}
