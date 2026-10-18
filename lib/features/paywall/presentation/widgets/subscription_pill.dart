import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/subscription.dart';

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

/// "Nov 18" this year, "Oct 18, 2027" otherwise.
String formatShortDate(DateTime d, {DateTime? now}) {
  final s = '${_months[d.month - 1]} ${d.day}';
  return d.year == (now ?? DateTime.now()).year ? s : '$s, ${d.year}';
}

/// The status under the name: Free plan, Free trial (days left), Premium
/// Monthly or Premium Yearly.
class SubscriptionPill extends StatelessWidget {
  const SubscriptionPill({super.key, required this.status});

  final SubscriptionStatus status;

  static String label(SubscriptionStatus s, DateTime now) {
    if (!s.isPremium) return 'Free plan';
    if (s.inTrial) {
      final d = s.trialDaysLeft(now);
      return 'Free trial · $d ${d == 1 ? 'day' : 'days'} left';
    }
    return s.plan == PremiumPlan.yearly
        ? 'Premium · Yearly'
        : 'Premium · Monthly';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (bg, fg) = !status.isPremium
        ? (c.surfaceMuted, c.textSecondary)
        : status.inTrial
        ? (const Color(0xFFFFF1D6), const Color(0xFFB7791F))
        : (c.softRose, c.accentText);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(9, 5, 12, 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.isPremium ? Icons.workspace_premium_rounded : Icons.circle,
            size: status.isPremium ? 15 : 8,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            label(status, DateTime.now()),
            style: AppTypography.title(12.5, fg, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
