/// The text of the in-app Privacy Policy and Terms of Use. Keep it in step
/// with docs/privacy-policy.md and docs/terms-of-use.md (the copies to host
/// at a URL for the App Store and Play Store listings).
class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

const legalUpdated = "October 18, 2026";

const privacySections = <LegalSection>[
  LegalSection(
    "Who we are",
    "Calesthetics is a calisthenics training app published by Verado Studio. This policy explains what the app stores, where it goes, and the choices you have. Questions: support@veradostudio.com.",
  ),
  LegalSection(
    "What the app stores",
    "Your training answers (goal, age range, equipment, schedule), your plan, finished workouts, favorites, personal records, reminder settings and the name you type in the app. If you create an account we also keep your email address and the display name you give, and your subscription status.",
  ),
  LegalSection(
    "Guests stay on the phone",
    "If you use the app without an account, everything stays on your device. Nothing is uploaded.",
  ),
  LegalSection(
    "Accounts and sync",
    "If you sign up or sign in (email, Google or Apple), your training data is saved in your account in Google Firebase (Firebase Authentication and Cloud Firestore) so it comes back when you sign in on another phone. Only you can read your data. When you sign out, the data is removed from the phone but stays in your account.",
  ),
  LegalSection(
    "Purchases",
    "Subscriptions are sold and billed by the Apple App Store or Google Play. We never see your card details. We use RevenueCat to check whether your subscription is active, which may process an anonymous app user ID or your account ID, and purchase information.",
  ),
  LegalSection(
    "Videos and pictures",
    "Exercise videos and pictures are delivered by a content delivery network (Bunny.net). Like any web request, this exposes your IP address to that service. We do not use it to identify you.",
  ),
  LegalSection(
    "What we do not do",
    "The app has no ads, no advertising trackers and no analytics profiling. We do not sell your data.",
  ),
  LegalSection(
    "Notifications",
    "Workout reminders are local notifications created on your phone. You can turn them off in the app or in system settings.",
  ),
  LegalSection(
    "Delete your data",
    "Profile, then Delete Account removes your account and your data from our servers, and clears everything from your phone. Without an account, Delete Account clears the data on your phone. You can also email support@veradostudio.com to ask for deletion.",
  ),
  LegalSection(
    "Children",
    "Calesthetics is not directed to children under 13, and we do not knowingly collect their data.",
  ),
  LegalSection(
    "Changes",
    "If this policy changes, the new version appears in the app with its date.",
  ),
];

const termsSections = <LegalSection>[
  LegalSection(
    "Using Calesthetics",
    "By using the app you agree to these terms. The app is provided by Verado Studio for personal, non-commercial use.",
  ),
  LegalSection(
    "Not medical advice",
    "Calesthetics is training guidance, not medical advice. Talk to a doctor before you start if you have an injury, a health condition, or are pregnant. Stop right away if anything hurts. You train at your own risk and within your own limits.",
  ),
  LegalSection(
    "Free and Premium",
    "The free plan includes one training plan. Premium unlocks every plan and every exercise in Discover.",
  ),
  LegalSection(
    "Subscriptions",
    "Premium is Monthly (\$9.99 per month, with a 7-day free trial for eligible new subscribers) or Yearly (\$49.99 per year). Prices can differ by country and are shown in the store before you buy.",
  ),
  LegalSection(
    "Billing and renewal",
    "Payment is charged to your Apple ID or Google Play account at confirmation of purchase. Subscriptions renew automatically at the end of each period unless you cancel at least 24 hours before it ends. Your account is charged for renewal within 24 hours before the end of the current period. Any unused part of a free trial is forfeited when you buy a subscription.",
  ),
  LegalSection(
    "Managing and canceling",
    "Manage or cancel in your App Store (Apple ID, Subscriptions) or Google Play (Payments and subscriptions) settings. Deleting the app does not cancel a subscription. Use Restore on the paywall to bring a purchase back on a new phone.",
  ),
  LegalSection(
    "Your account",
    "You are responsible for your sign-in details. You can delete your account at any time in Profile.",
  ),
  LegalSection(
    "Content",
    "The app, its videos, pictures and text belong to Verado Studio. You may not copy or resell them.",
  ),
  LegalSection(
    "Changes and contact",
    "We may update these terms and the app. Questions: support@veradostudio.com.",
  ),
];
