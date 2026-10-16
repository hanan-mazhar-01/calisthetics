enum CoachRole { user, coach }

class CoachMessage {
  const CoachMessage(this.role, this.text);
  final CoachRole role;
  final String text;
}
