/// Where the Privacy Policy and Terms of Service are published on the web
/// (the Blogger pages built from legal_pages/).
///
/// Paste the two addresses here once the pages are live, or pass them at
/// build time: `--dart-define=PRIVACY_POLICY_URL=https://...`
/// `--dart-define=TERMS_OF_SERVICE_URL=https://...`.
/// While a value is empty the app shows its own copy of that text instead,
/// which also works offline.
const privacyPolicyUrl = String.fromEnvironment(
  'PRIVACY_POLICY_URL',
  defaultValue: '',
);
const termsOfServiceUrl = String.fromEnvironment(
  'TERMS_OF_SERVICE_URL',
  defaultValue: '',
);

/// The page to open on the web, or null when no valid web address is set
/// (then the in-app text is shown). Only https addresses are used.
Uri? webAddress(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}
