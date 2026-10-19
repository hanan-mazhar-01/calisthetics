# 🍎 APP STORE AUDIT REPORT

## App
**Calesthetics** (package `calisthenics`, bundle id `com.veradostudio.calisthenics`), by Verado Studio. Flutter, iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), iOS 15+.

## Audit date
2026-10-19

## Overall status
**`NOT READY`** today. It becomes **`READY AFTER FIXES`** once the four blockers below are done (the icon, the live URLs, a real iOS build, and the in-app-purchase set-up). Nothing here guarantees approval.

Labels used: **CONFIRMED** (seen in the code or by a live call), **LIKELY**, **UNVERIFIED** (cannot be seen from this machine: needs Xcode, App Store Connect, RevenueCat dashboard, sandbox/TestFlight or an iPhone).

---

# PHASE 1: DISCOVERY

| Question | What the code shows |
|---|---|
| Purpose | A guided calisthenics training app for women: onboarding builds a 4-week plan, daily workouts with coached videos, an exercise library (Discover), progress/achievements, reminders. |
| Audience | Adults (age choices start at 18–24). Not a Kids-category app. |
| Monetization | Free = one plan. Premium = every plan + every Discover exercise/video. **Monthly $9.99 with a 7-day trial**, **Yearly $49.99**, via Apple IAP through **RevenueCat** (iOS key built in; Android key still missing). |
| AI | **None.** No AI SDK, API, key or call anywhere (`pubspec.yaml`, `lib/`). |
| User-generated content | None shared. The only share is an achievement-card image + one line, made on the phone (`share_plus`). |
| Authentication | Optional. Guest mode works fully. Email/password, Google, and **Sign in with Apple on iPhone only** (hidden on Android). Account deletion in-app. |
| Data | Guest: only on the phone. Account: one private Firestore document per user (`users/{uid}`, rules deployed). |
| SDKs | See the SDK table below. **No analytics, crash-reporting, advertising or attribution SDK.** |
| Permissions | Only notifications (when the user switches Reminders on). No camera, photos, microphone, location, contacts, tracking. |
| External content | Exercise videos (Bunny Stream) and pictures (Bunny storage), both the developer's own library; fonts bundled. |
| External payment | None (no Stripe/PayPal/web checkout in the app). |

Architecture: UI → Riverpod providers → services (auth, sync, subscription, reminders) → Firebase / RevenueCat / Bunny. Main flow: Welcome → onboarding (optional paywall, optional account) → Plan / Discover / Progress / Profile.

---

# PHASE 2: RISKS

## 🔴 BLOCKERS

| # | Issue | Apple area | Evidence | Fix |
|---|---|---|---|---|
| B1 | **The iOS app icon is the default Flutter "F".** (CONFIRMED) | 2.1 App Completeness / 2.3 (placeholder assets). Placeholder icons are a routine rejection. | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` is the blue Flutter logo on white. | Make the real icon (1024×1024, no transparency, no rounded corners), regenerate the whole set. Needs your brand decision. |
| B2 | **Privacy Policy URL and Support URL are not live.** (CONFIRMED) | 5.1.1(i) privacy policy link in App Store Connect; 1.5 support URL. Both are mandatory fields. | The three pages exist in `legal_pages/` but are not published; `legal_links.dart` has empty addresses, so the app shows its in-app copy. | Publish `privacy-policy.html`, `terms-of-service.html`, `help-support.html` on Blogger; put the Privacy URL and Support URL in App Store Connect; give the three addresses to the app (`legal_links.dart` or `--dart-define`). |
| B3 | **No iOS build has ever been compiled or run.** (CONFIRMED: there is no `Podfile`, no `Pods`, no Mac here.) | 2.1 App Completeness (crashes), and everything iPhone-only is untested. | Sign in with Apple, StoreKit purchases, notifications, Google sign-in on iOS, HLS video were only ever reasoned about. | On a Mac: `flutter build ios`, run on a real iPhone, upload to TestFlight, work through the test plan below. |
| B4 | **In-App Purchase set-up cannot be seen from here.** (UNVERIFIED, but a miss means the reviewer cannot buy) | 2.1 / 3.1.1 / 3.1.2 | RevenueCat side checked live: `default` offering is current; `$rc_monthly` → `calisthenics_subscription_monthly`, `$rc_annual` → `calisthenics_subscription_yearly`. Nothing about App Store Connect, the `premium` entitlement attachment, or the RevenueCat App Store key can be read. | Do the App Store Connect and RevenueCat checklist in section "Human checks". |

## 🟠 HIGH RISKS

| # | Issue | Risk | Evidence | Fix |
|---|---|---|---|---|
| H1 | **Content provenance and licences.** Developer's statement: videos and images were made with **Google Flow**; the background music was **taken from YouTube** (the title is not recorded anywhere: not in the project, not in the file's tags). (CONFIRMED statement, licences UNVERIFIED) | 5.2 Intellectual Property. **Music taken from YouTube is copyrighted unless the video says otherwise** (YouTube Audio Library, Creative Commons, or a purchased licence). Using it in a paid app can lead to rejection or a takedown. Naming the track in the legal pages is a credit, not permission. | `assets/audio/gym_background_music.mp3` is a 2:21 file made from a browser download (`videoplayback.webm`); no title/artist tag. Flow: its terms decide whether the plan used allows commercial use and removing its visible mark (unverified). | Music: find the original video, check its licence; if CC BY keep it and fill the credit line (`MUSIC_CREDIT` in `tool/legal_content.py`); if it is a normal song, replace the file with a licensed royalty-free track (same file name). Flow: keep the terms of the plan you used. The legal pages now disclose AI-generated media and have a Credits line. |
| H2 | **EULA arrangement not decided.** (UNVERIFIED) | 3.1.2 (terms must be available). | The Terms say Apple's standard end-user terms also apply and Apple is a third-party beneficiary. | Simplest: keep Apple's standard EULA and add a link to your Terms page in the App Description. If you upload a custom EULA instead, it must contain Apple's minimum terms and a developer address. |
| H3 | **Privacy label in App Store Connect must match the code.** (UNVERIFIED) | 5.1.1 / privacy nutrition label accuracy. | See the privacy table. The app collects health-type answers ("areas to protect"). | Fill the label from the table below. |
| H4 | **Age rating and health wording.** (UNVERIFIED) | 1.4.1 physical harm / age-rating questionnaire. | In-app disclaimer exists (onboarding "A quick health note", Terms section 2). | Answer the questionnaire consistently with a fitness app that gives workout guidance, no medical claims. |

## ✅ FIXED DURING THIS AUDIT (committed, tests pass: 653)

| # | What was wrong (CONFIRMED) | Fix | Commit |
|---|---|---|---|
| F1 | **Reminders could never be turned on on iPhone.** `LocalReminderService` set up only Android, so on iOS it never asked permission and could not schedule. A visible feature that does nothing (2.1). | iOS initialisation, permission request when the switch is turned on, iOS notification details. **Needs a real iPhone to confirm.** | `c43bd34` |
| F2 | **Paywall could show typed-in prices** ($9.99 / 7-day trial / "Save 58%") when the store's offers failed to load, and then fail on purchase. | With real payments only store prices are shown; if offers cannot load the paywall says so with **Try again**; "Save N%" is computed from real prices. | `e4a41c2` |
| F3 | **Trial promised even if the user already had it.** | On iPhone the trial is shown only when Apple's eligibility check says eligible. | `e4a41c2` |
| F4 | **Thin renewal disclosure.** | Text by the button: charged to the Apple ID (or Google Play) at confirmation / when the trial ends, renews automatically, cancel 24 h before, where to manage. | `e4a41c2` |
| F5 | **Manage Subscription had no real link; a failed restore failed silently.** | "Manage in the App Store / Google Play" button; restore errors now show a message. | `e4a41c2` |
| F6 | **Privacy manifest missed Health and Other data.** | `PrivacyInfo.xcprivacy` now declares Health (areas to protect) and Other data. | `08823a4` |
| F7 | **Premium status was synced through the user's own Firestore document** (user-editable). | It is no longer uploaded or taken back; RevenueCat is the only truth. | `08823a4` |

## 🟡 MEDIUM RISKS

| # | Issue | Risk | Evidence | Fix |
|---|---|---|---|---|
| M1 | Offline, the saved Premium status has no expiry check. | A lapsed subscriber keeps Premium until the app next reaches RevenueCat. Low abuse, but a correctness gap. | `RevenueCatSubscriptionService.cached` reads the saved value without comparing `renewsAt`. | Treat a saved status past its renewal date (plus a short grace) as free until refreshed. |
| M2 | The in-app legal/help text mentions Google Play and Android on iPhone. | 2.3.10 (other platforms). Low: normal in cross-platform terms, and the paywall/manage UI is platform-aware. | `tool/legal_content.py` is shared by both platforms. | Optional: platform-specific copy, or accept. |
| M3 | Premium is protected only in the app. | Not an Apple issue: free users cannot see locked videos in the UI, but the Bunny library only checks a `Referer` header. | `exercise_videos.dart` | Bunny token authentication, later. |
| M4 | Unreachable leftover code with placeholder wording. | If a route were ever reachable it would show "Coming soon". Not reachable today. | `features/coach/*` (`TODO(owner)` quota), `SettingsScreen` ("Coming soon" rows, route `/settings` never navigated to), `CloudinaryMediaRepository` (unused). | Delete before release. |
| M5 | Launch screen is blank white. | Flash in dark mode. Cosmetic. | `LaunchScreen.storyboard`, 68-byte `LaunchImage`. | Match the app background. |
| M6 | No dedicated "billing issue" state. | RevenueCat keeps the entitlement active during Apple's grace period, so access is right; there is just no message. | `SubscriptionStatus` has no such state. | Optional. |
| M7 | Firebase iOS API key restrictions unknown. | The key is a public identifier, but should be limited to the bundle id. | `lib/firebase_options.dart` (iOS key). | In Google Cloud, restrict the iOS key to `com.veradostudio.calisthenics`. |
| M8 | Account deletion does not remove the RevenueCat customer record, and the Privacy Policy does not say what happens to it. | 5.1.1(v) completeness of deletion statement. | `AccountSession.deleteAccount` calls `Purchases.logOut` only. | Add a sentence to the policy (billing records are kept as the stores/law require) or delete the customer via RevenueCat's API. |
| M9 | Policy has no postal address / generic governing law. | Legal completeness. | `tool/legal_content.py` | Have counsel review. |
| M10 | `debugPrint` calls stay in release builds. | Low: they print error text only, never personal data. | 14 occurrences. | Optional. |

## 🟢 VERIFIED PASS

| Area | Result | Evidence |
|---|---|---|
| No AI | PASS | no AI package/SDK/URL in `pubspec.yaml` or `lib/`. AI sections of the master list do not apply. |
| No analytics / ads / tracking SDK | PASS | `pubspec.lock` has none; `NSPrivacyTracking` is false; no ATT prompt needed. |
| No external payment for digital goods | PASS | grep for stripe / paypal / checkout / web billing in `lib/` and `ios/Runner`: nothing. Purchases only via RevenueCat → Apple IAP. |
| Permissions | PASS | `Info.plist` has no camera/photos/microphone/location strings and none are needed. Notifications are asked only when the user switches Reminders on. |
| Account deletion in-app | PASS (Android verified live; iOS code path reviewed) | Profile > Delete Account; deletes Firestore document + sign-in account; revokes the Sign in with Apple token on iPhone; guests get "Erase data on this phone". |
| Sign in with Apple | PASS in code, UNVERIFIED on device | Offered on iPhone only, nonce-protected, entitlement present (`Runner.entitlements`), Google sign-in present so Apple's equivalent-login rule is met. |
| App usable without an account | PASS | Guest mode; the account step and the paywall both have Skip / Not now. |
| Restore purchases | PASS | Paywall "Restore" and Profile > Manage > Restore purchases, both with error messages. |
| Terms/Privacy next to the paywall | PASS | "Terms" and "Privacy" links under the buy button. |
| Paywall truthfulness (after F2–F4) | PASS | Prices, trial and "Save N%" come from the store; the buy button buys the selected plan (test: choosing Yearly calls `purchase(yearly)`). |
| Secrets | PASS | Repo and git history searched: only Firebase client config (public by design) and the RevenueCat public key. Bunny storage/stream keys are outside the repo (`~/.config/calesthetics/bunny.env`). |
| Firestore rules | PASS | `users/{uid}` only, owner only, field allow-list; everything else denied. (Deployed 2026-10-18.) |
| Network | PASS | No `http://` anywhere; no ATS exceptions; hosts are DNS names (IPv6-safe); videos handle offline/failed loads with a labelled placeholder. |
| Export compliance | PASS | `ITSAppUsesNonExemptEncryption = false` (standard HTTPS only). |
| Device family | PASS | iPhone only; portrait only (matches the app's design). |
| Health/claims | PASS | No guarantees or medical claims (searched); disclaimer in onboarding and Terms. |
| Privacy Policy content | PASS | Generated from the real data flows; names Firebase, RevenueCat, Bunny.net, Apple/Google; says no analytics/ads. |
| Subscription products in RevenueCat | PASS (live call) | Offering `default` current: `$rc_monthly` → `calisthenics_subscription_monthly`, `$rc_annual` → `calisthenics_subscription_yearly`. |

## ⚪ HUMAN CHECK REQUIRED

| Item | Where to check | Why |
|---|---|---|
| App icon, replaced | Xcode asset catalog | B1 |
| Three pages published; Privacy URL and Support URL entered | Blogger, App Store Connect | B2 |
| Sign in with Apple + In-App Purchase capabilities enabled for the App ID; signing team set | Apple Developer, Xcode | needed for build/upload |
| Build runs on a real iPhone; archive validates (no privacy-manifest warnings from pods) | Xcode / TestFlight | B3 |
| Subscription group with both products; IDs exactly `calisthenics_subscription_monthly` and `calisthenics_subscription_yearly`; monthly has a 7-day free introductory offer; prices $9.99 / $49.99; availability; localisation; review screenshot; status "Ready to Submit" and attached to the version | App Store Connect | B4, 3.1.2 |
| Both products in the **same** subscription group (so Monthly ↔ Yearly is an upgrade/downgrade, not two subscriptions) | App Store Connect | 3.1.2 |
| Both products attached to the `premium` entitlement; App Store Connect in-app-purchase key added to RevenueCat; restore behaviour set | RevenueCat dashboard | B4 |
| Firebase: Apple provider enabled; iOS API key restricted to the bundle id | Firebase / Google Cloud | sign-in works, M7 |
| Privacy nutrition label filled from the table below; "Data Used to Track You" = none | App Store Connect | H3 |
| Age rating questionnaire | App Store Connect | H4 |
| EULA choice (Apple standard + Terms link in description, or a custom EULA) | App Store Connect | H2 |
| Licences for videos, pictures, artwork, music | your records | H1 |
| App name available; description, keywords, screenshots (6.9" and 6.5") truthful; review notes pasted | App Store Connect | metadata |
| Backend stays live during review (Firebase, Bunny CDN, RevenueCat) | each dashboard | 2.1 |

---

# 💳 REVENUECAT REPORT

**Products** (CONFIRMED live): `calisthenics_subscription_monthly`, `calisthenics_subscription_yearly`.
**Offerings**: `default` (current), packages `$rc_monthly` and `$rc_annual`. The app reads `offering.monthly` / `.annual`, so these package identifiers must stay as they are.
**Entitlement**: code checks `premium` (`RevenueCatSubscriptionService.entitlementId`). UNVERIFIED that both products are attached to it.

| Item | Result |
|---|---|
| Monthly | Shows the store price; trial text only when the product has an intro offer **and** (iPhone) Apple says the user is eligible. |
| Yearly | Never claims a trial. Buy button buys `offering.annual` (tested). |
| Trial | UNVERIFIED in sandbox. Code: `PeriodType.trial` → `inTrial`, "Free trial · N days left" on Profile. |
| Purchase | `Purchases.purchase(package)` → customer info → entitlement → Premium UI + a welcome screen. Cancel by the user is silent; real errors show a message. |
| Restore | Paywall + Manage; shows "Your Premium is active." / "No active subscription was found." / error text. |
| Manage | Profile > Manage: Switch plan, Restore, **Manage in the App Store** (new). |
| Upgrade/downgrade | Switching opens the paywall; the store performs the change if both products share a group. UNVERIFIED. |
| Account identity | `Purchases.logIn(uid)` after sign-in, `logOut()` after sign-out/deletion; saved status is wiped on sign-out. A→B switch cannot leak Premium (status is wiped; RevenueCat re-reads). Deletion keeps the RevenueCat record (M8). |
| Source of truth | RevenueCat customer info (`premium`). A saved copy gives instant UI and offline use (M1). It no longer travels through Firestore (F7). |
| Subscription state | See table below. |
| App restart | Saved status shows instantly, then refreshes. |
| Reinstall | Restore / sign-in re-reads from RevenueCat. UNVERIFIED on device. |

**State machine (expected vs code):**

| State | Expected UI | Premium | Code |
|---|---|---|---|
| No subscription | Paywall | No | ✅ |
| Trial active | "Free trial · N days left", Manage | Yes | ✅ (`periodType == trial`) |
| Monthly / Yearly active | "Premium · Monthly/Yearly", Manage; same-plan button says "Your current plan" and is disabled | Yes | ✅ |
| Cancelled but active | Active until end date | Yes | ✅ entitlement stays active until expiry |
| Expired | Paywall | No | ✅ after refresh; ⚠️ offline stale (M1) |
| Billing issue | Active during grace, no message | Yes | ⚠️ no message (M6) |
| Restore success / none | Active / "No active subscription" | Yes / No | ✅ |

# 🤖 AI REPORT

Provider: **none**. Model: none. User data sent to an AI: **none**. Images sent: **none** (the app has no camera/photo access). Storage/retention: not applicable. Safety/accuracy claims: the app makes no AI claims. Metadata must not claim AI either.

# 🔐 PRIVACY REPORT

Data collected (only when the user creates an account; guests keep everything on the phone): email, name, account id, onboarding answers (goals, experience, schedule, equipment, age range, "areas to protect"), workout history/favourites/settings, subscription status (through RevenueCat/Apple).
Shared with: Google (Firebase Auth, Firestore, Google sign-in), Apple (sign-in, billing), RevenueCat (subscription status), Bunny.net (delivers public videos/pictures; receives only normal request data).
Analytics/crash/ads: **none**. Tracking: **No** (`NSPrivacyTracking` false, no tracking domains).
Account deletion: in-app (see PASS). Policy: published as a generated page, same text as in the app.

**Privacy label (fill in App Store Connect; mirrors `PrivacyInfo.xcprivacy`):**

| Data | Collected? | Linked to user? | Tracking? | Purpose | Notes |
|---|---|---|---|---|---|
| Email address | Yes (account) | Yes | No | App functionality | |
| Name | Yes (account / profile) | Yes | No | App functionality | |
| User ID | Yes (Firebase uid; RevenueCat id) | Yes | No | App functionality | |
| Health | Yes ("areas to protect") | Yes | No | App functionality | added in F6 |
| Fitness | Yes (workout history, progress) | Yes | No | App functionality | |
| Purchase history | Yes (subscription status) | Yes | No | App functionality | |
| Other data | Yes (goals, age range, equipment, schedule) | Yes | No | App functionality | added in F6 |
| Device ID / IP | Via RevenueCat and Firebase as part of their service | Check each provider's own privacy documentation | No | App functionality | UNVERIFIED: confirm against RevenueCat and Firebase docs |
| Contacts, location, photos, camera, microphone, browsing, search | No | | | | |

**SDKs**

| SDK | Purpose | Network | Privacy impact | Configuration |
|---|---|---|---|---|
| firebase_core / firebase_auth / cloud_firestore | accounts, synced data | Yes | email, uid, user data | iOS options in `firebase_options.dart`; Apple provider must be enabled |
| google_sign_in | Google sign-in | Yes | email, name | URL scheme in `Info.plist` matches the iOS client id ✅ |
| sign_in_with_apple | Apple sign-in | Yes | email (maybe relay), name | entitlement present ✅ |
| purchases_flutter | subscriptions | Yes | purchase status, ids | iOS public key built in ✅ |
| flutter_local_notifications, timezone, flutter_timezone | reminders (local only) | No | none leaves the phone | fixed for iOS (F1) |
| video_player, cached_network_image, flutter_cache_manager | videos/pictures | Yes (Bunny) | none beyond requests | HTTPS |
| audioplayers, vibration | music, haptics | No | none | |
| share_plus | share a card | No | none | |
| url_launcher | open web pages / mail | No | none | |
| shared_preferences | local storage | No | none | `UserDefaults` reason CA92.1 declared ✅ |

# 📚 DATA SOURCE REPORT

| Feature | Data | Source | License/Terms | Attribution | Status |
|---|---|---|---|---|---|
| Workout videos (115 exercises, 98 with coached videos) | 30 s and 10 s clips | Made by the developer with Google Flow, hosted on Bunny Stream | Flow's terms for the plan used (commercial use, removing its visible mark) UNVERIFIED | AI disclosure added to Terms, Privacy, Help | ⚪ H1 |
| Exercise pictures / thumbnails | WebP images | Made with Google Flow, hosted on Bunny storage (`calisthetics.b-cdn.net`) | Flow's terms UNVERIFIED | AI disclosure added | ⚪ H1 |
| Onboarding artwork (3D-style badges, icons) | images | Bunny storage | Mixed: some AI-made, the pull-up badge and nav icons are original vector drawings; tool terms UNVERIFIED | none if owned | ⚪ H1 |
| Background music | `assets/audio/gym_background_music.mp3` | A YouTube video (title not recorded) | **no licence on record** | credit line ready (`MUSIC_CREDIT`), empty until the title and licence are known | 🔴→⚪ H1 |
| Fonts | Poppins, Lora | bundled | SIL Open Font License | licence text should ship with the fonts (optional in UI) | ✅ |
| Icons | Material icons + custom drawings | Flutter / own | Apache-2.0 / own | none | ✅ |
| Exercise text, plans | written for the app | developer | own | none | ✅ |

---

# 🧪 TEST PLAN (TestFlight, real iPhone)

Result column = what is known now. "Android" means verified on the test phone earlier in this project.

| # | Test | Steps | Now |
|---|---|---|---|
| 01 | Fresh install | Install, open, onboard as guest | PASS on Android; **UNVERIFIED iPhone** |
| 02 | Create account | Account step → Apple / Google / email | Android PASS (Google); **UNVERIFIED iPhone (Apple)** |
| 03 | Login | Sign out, log in | Android PASS; iPhone UNVERIFIED |
| 04 | Core feature | Start Day 1, finish, rate | Android PASS; iPhone UNVERIFIED |
| 05 | Invalid input | (no free-text/image input exists) | N/A |
| 06 | Network failure | Airplane mode, open a never-played video | Code handles (placeholder); iPhone UNVERIFIED |
| 07 | Monthly subscription | Paywall → Monthly → Start free trial (sandbox) | UNVERIFIED |
| 08 | Yearly subscription | Yearly → Continue (sandbox); confirm the Yearly product was charged | UNVERIFIED (unit test proves `purchase(yearly)`) |
| 09 | Trial | Trial shows once; second Apple ID that used it sees no trial text | UNVERIFIED |
| 10 | Restore | Reinstall → Restore | UNVERIFIED |
| 11 | App restart | Buy → kill → reopen: still Premium | UNVERIFIED |
| 12 | Logout/login | Sign out → in: Premium follows the account | UNVERIFIED |
| 13 | Account deletion | Profile > Delete Account; Apple confirms; sign in again = fresh account | Android PASS (Google); iPhone UNVERIFIED |
| 14 | Privacy policy | Profile > Privacy Policy opens | PASS (in-app); web URL pending B2 |
| 15 | Permission denial | Deny notifications, switch Reminders on: the sheet says notifications are blocked | Android: on/off verified, denial path not tried; **iPhone UNVERIFIED (F1)** |
| 16 | Subscription management | Manage → "Manage in the App Store" opens Apple's page | UNVERIFIED |
| 17 | Expired subscription | Let the sandbox subscription lapse | UNVERIFIED |
| 18 | Billing failure | Sandbox billing retry | UNVERIFIED |
| 19 | Different device | Sign in on a second iPhone, Restore | UNVERIFIED |
| 20 | Fresh reinstall | Delete app, reinstall, sign in | UNVERIFIED |

# 📝 APP REVIEW NOTES (ready to paste)

Written for: the Apple App Review team.

> **Calesthetics** is a guided calisthenics training app: a short onboarding builds a 4-week plan, then each day opens a workout with coached exercise videos, rest timers and progress tracking. It has no AI features and no user-generated content.
>
> **No login is required.** Everything except Premium works as a guest: tap "Start my journey", answer the questions, and on the last two screens tap "Not now" (paywall) and "Skip" (account). An account is optional and only saves the plan across devices. To try it, you can choose Sign in with Apple or Google on the account screen, or Profile > Sign in / Sign up. **Account deletion:** Profile > Delete Account (as a guest the same row reads "Erase data on this phone").
>
> **Subscriptions (Premium):** the paywall appears at the end of onboarding and from Profile > Premium / Upgrade. Two auto-renewable subscriptions in one group: **Monthly** ($9.99, 7-day free trial for new subscribers) and **Yearly** ($49.99). Premium unlocks every plan and every exercise/video in Discover. Free keeps one plan. **Restore** is on the paywall and in Profile > Manage. Manage/cancel: Profile > Manage > "Manage in the App Store".
>
> **Where to look:** the Plan tab shows the plan day by day (days unlock in order). Open a day and tap START for the workout player (the music button at the top right opens a Music on/off and volume panel). Discover lists all exercises; videos for exercises outside the free plan are Premium. Reminders: Profile > Reminders (asks for notification permission).
>
> Videos stream from our CDN the first time they play, so the device needs an internet connection. All backend services are live.

# 🚀 FINAL PRE-SUBMISSION CHECKLIST

Only ticked when verified.

### Core app
- [x] App launches (Android phone) · [ ] on iPhone
- [x] No crash in the Android walk-through (home → profile) · [ ] on iPhone
- [x] Core feature works (Android) · [ ] iPhone
- [x] No AI (nothing to test)
- [x] Error handling for offline videos exists in code · [ ] seen on iPhone
- [x] Permissions correct (only notifications)
- [ ] Backend live during review

### Account
- [x] Signup/login/logout (Android, Google) · [ ] Apple on iPhone
- [x] Account deletion (Android) · [ ] iPhone
- [x] Sign in with Apple present in code · [ ] works on device
- [x] Demo account not needed (guest mode)

### RevenueCat
- [x] Offering/products match code (live call)
- [ ] Entitlement attachment · [ ] Monthly purchase · [ ] Yearly purchase · [ ] Trial · [ ] Restore (sandbox)
- [x] Active-plan button state (tested) · [x] Manage button (code + test)
- [ ] Upgrade/downgrade (same subscription group) · [ ] Restart · [ ] Reinstall

### Privacy
- [x] Privacy Policy written · [ ] published and entered in App Store Connect
- [x] No AI disclosure needed · [x] Third parties named in the policy
- [x] No permission strings needed
- [ ] Privacy label entered · [x] Tracking = none (code)
- [x] Data deletion in app

### Sources
- [x] APIs/CDNs identified
- [ ] Licences checked (videos, pictures, artwork, music)

### Store
- [ ] Metadata accurate · [ ] Screenshots · [ ] Age rating · [ ] Category
- [x] Review notes drafted · [ ] IAP submitted with the version · [ ] Subscription metadata complete
- [ ] **App icon replaced (B1)**

---

# PHASE 3: FIX PLAN

**P0, before submitting**
1. Replace the app icon (B1): your brand decision.
2. Publish the three pages and enter Privacy URL + Support URL (B2).
3. Build on a Mac, run on an iPhone, upload to TestFlight (B3).
4. Do the App Store Connect + RevenueCat subscription checklist and a sandbox purchase (B4).
5. Fill the privacy label and the age rating; choose the EULA arrangement.

**P1, strongly recommended**
6. Write down the licence/ownership of the videos, pictures, artwork and music (H1).
7. Restrict the Firebase iOS API key (M7).
8. Offline expiry check for the saved Premium status (M1).
9. Privacy Policy sentence about RevenueCat records after deletion (M8).

**P2, nice to have**
10. Delete unreachable placeholder code (M4), launch screen colour (M5), billing-issue message (M6), Bunny token authentication (M3).
