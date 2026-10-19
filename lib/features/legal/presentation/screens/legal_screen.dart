import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/legal_text.dart';

enum LegalKind { privacy, terms, support }

const _supportEmail = 'support@veradostudio.com';

/// A paragraph that starts with this is a sub-heading (a question).
const _subheading = '## ';

/// The Privacy Policy, the Terms of Use or Help & Support, readable offline,
/// from the profile, the settings and the paywall. Help & Support also has a
/// button that starts an email to us.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});

  final LegalKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (title, sections) = switch (kind) {
      LegalKind.privacy => ('Privacy Policy', privacySections),
      LegalKind.terms => ('Terms of Use', termsSections),
      LegalKind.support => ('Help & Support', supportSections),
    };
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
                      title,
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
                  if (kind == LegalKind.support) ...[
                    const SizedBox(height: 16),
                    const _EmailButton(),
                  ],
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
                    for (final part in s.body.split('\n\n'))
                      if (part.startsWith(_subheading))
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 2),
                          child: Text(
                            part.substring(_subheading.length),
                            style: AppTypography.title(
                              15,
                              c.textPrimary,
                              weight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            part,
                            style: AppTypography.body(
                              c.textSecondary,
                              fontSize: 14.5,
                              height: 1.5,
                            ),
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

/// "Email us": opens the phone's mail app with our address and a subject;
/// if there is no mail app, copies the address instead.
class _EmailButton extends StatelessWidget {
  const _EmailButton();

  Future<void> _write(BuildContext context) async {
    final uri = Uri.parse(
      'mailto:$_supportEmail?subject=${Uri.encodeComponent('Calesthetics support')}',
    );
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {}
    if (opened || !context.mounted) return;
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Email address copied')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: 'Email $_supportEmail',
      excludeSemantics: true,
      child: Material(
        color: c.accent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _write(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline_rounded, size: 20, color: c.onAccent),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Email $_supportEmail',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title(
                      15,
                      c.onAccent,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
