import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/legal_links.dart';
import 'screens/legal_screen.dart';

/// Opens the Privacy Policy or the Terms of Service: the published web page
/// when its address is set (in the phone's browser), otherwise the copy
/// inside the app. If the browser cannot open it, the in-app copy shows.
Future<void> openLegal(BuildContext context, LegalKind kind) async {
  final privacy = kind == LegalKind.privacy;
  final web = webAddress(privacy ? privacyPolicyUrl : termsOfServiceUrl);
  if (web != null) {
    try {
      if (await launchUrl(web, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Fall back to the text inside the app.
    }
  }
  if (!context.mounted) return;
  context.push(privacy ? '/privacy' : '/terms');
}
