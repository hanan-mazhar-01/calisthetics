import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/legal_text.dart';

enum LegalKind { privacy, terms }

/// The Privacy Policy or the Terms of Use, readable offline, from the
/// profile, the settings and the paywall.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});

  final LegalKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final privacy = kind == LegalKind.privacy;
    final sections = privacy ? privacySections : termsSections;
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
                      privacy ? 'Privacy Policy' : 'Terms of Use',
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
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  MediaQuery.paddingOf(context).bottom + 28,
                ),
                children: [
                  Text(
                    'Calesthetics by Verado Studio · Updated $legalUpdated',
                    style: AppTypography.body(c.textMuted, fontSize: 12.5),
                  ),
                  for (final s in sections) ...[
                    const SizedBox(height: 22),
                    Text(
                      s.heading,
                      style: AppTypography.title(
                        16,
                        c.textPrimary,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.body,
                      style: AppTypography.body(
                        c.textSecondary,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
