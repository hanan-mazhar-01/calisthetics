import '../../user/domain/completed_session.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _monthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Activities finished on [day], oldest first.
List<CompletedSession> activitiesOn(
  List<CompletedSession> history,
  DateTime day,
) =>
    history.where((s) => dayOf(s.finishedAt) == dayOf(day)).toList()
      ..sort((a, b) => a.finishedAt.compareTo(b.finishedAt));

/// "Oct 13, 11:24 AM".
String activityStamp(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour < 12 ? 'AM' : 'PM';
  return '${_months[d.month - 1]} ${d.day}, $h:$m $ap';
}

/// "OCT 13 2026" — the title of a day page.
String dayTitle(DateTime d) =>
    '${_months[d.month - 1].toUpperCase()} ${d.day} ${d.year}';

/// "October 13, 2026" — the date row of the add-activity form.
String longDate(DateTime d) =>
    '${_monthsLong[d.month - 1]} ${d.day}, ${d.year}';

/// "October 2026" — the calendar heading.
String monthTitle(DateTime d) => '${_monthsLong[d.month - 1]} ${d.year}';

/// A hand-logged activity, stamped on [day]: now if that is today, else noon.
CompletedSession manualActivity({
  required String name,
  required int minutes,
  required DateTime day,
  required DateTime now,
}) {
  final sameDay = dayOf(day) == dayOf(now);
  return CompletedSession(
    finishedAt: sameDay ? now : DateTime(day.year, day.month, day.day, 12),
    templateId: CompletedSession.manualTemplateId,
    sessionName: name.trim(),
    durationSeconds: minutes * 60,
    exerciseNumbers: const [],
  );
}
