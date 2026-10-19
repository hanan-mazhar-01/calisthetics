import 'package:flutter/foundation.dart';

/// Sign in with Apple is offered on iPhone, iPad and Mac only. Android (and
/// the web) show Google and email, because Apple's sign-in there is a web
/// page the app was never set up for.
bool appleSignInAvailableOn(TargetPlatform platform, {bool web = false}) =>
    !web &&
    (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS);

/// [appleSignInAvailableOn] for the platform the app is running on.
bool get appleSignInAvailable =>
    appleSignInAvailableOn(defaultTargetPlatform, web: kIsWeb);
