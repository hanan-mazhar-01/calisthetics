"""The text of the Privacy Policy, the Terms of Service and the Help & Support
page of Calesthetics.

The ONE place to edit the wording. `python3 tool/build_legal_pages.py` turns it
into the three web pages (legal_pages/) and the in-app copy
(lib/features/legal/domain/legal_text.dart).

Only things the app really does are written here (checked against the code):
no analytics, ads or crash-reporting SDKs; Firebase Auth + Cloud Firestore for
accounts; Apple / Google billing with RevenueCat for subscriptions; Bunny.net
for the videos and pictures; local reminder notifications; no camera,
microphone, location or health-data access.

Blocks:  ("p", text) | ("h3", text) | ("ul", [items]) | ("code", text)
         ("warn", title, text)
Inline:  **bold**, [[privacy]] / [[terms]] / [[support]] (link to the other
         page), [[email]] becomes a mail link.
"""

APP = "Calesthetics"
PUBLISHER = "Verado Studio"
EMAIL = "support@veradostudio.com"
EFFECTIVE = "October 19, 2026"
UPDATED = "October 19, 2026"

# Credit for the workout background music (assets/audio/gym_background_music.mp3),
# shown in the Terms ("Credits") and Help & Support once it is filled in:
# title, artist, where it comes from and the licence it is used under, e.g.
#   '"Song Title" by Artist (youtube.com/..., licence: CC BY 4.0).'
# Left empty, no music credit is printed. Do not publish a credit that is not
# backed by a real licence: a credit is not permission.
MUSIC_CREDIT = ""

CREDIT_ITEMS = (
    (["**Music:** " + MUSIC_CREDIT] if MUSIC_CREDIT else [])
    + ["**Fonts:** Poppins and Lora, under the SIL Open Font License."]
)

# ---------------------------------------------------------------- privacy ---
PRIVACY = {
    "title": "Privacy Policy",
    "badge": "Official Policy Document",
    "box": (
        "\U0001F512",
        "Our Core Privacy Principle",
        "**We do NOT sell, rent, monetize, or share your personal information, "
        "training history, or subscription records with third-party advertisers, "
        "data brokers, or marketing networks.** Your answers and progress are used "
        "only to build your plan, keep your progress, and let it follow you to a "
        "new phone if you create an account. Without an account, everything "
        "stays on your phone.",
    ),
    "sections": [
        {
            "title": "Information We Collect and Purpose of Collection",
            "blocks": [
                ("p", "Calesthetics collects only the information needed to build "
                      "your training plan, track your progress, and run your "
                      "subscription. **If you use the app as a guest, none of it "
                      "leaves your phone.**"),
                ("h3", "A. Training Profile & Preferences"),
                ("ul", [
                    "**What We Collect:** Your answers while setting up your plan: "
                    "goal, age range, where you train, equipment, experience, days "
                    "per week, session length, preferred time of day, focus areas, "
                    "your plank test result, and the first name you type in. You "
                    "may also choose \"areas to protect\" (for example knees or "
                    "wrists); this is optional.",
                    "**Why We Collect It:** To choose and build your plan and to "
                    "avoid exercises that load an area you asked us to protect. "
                    "The plan is built by fixed rules from your answers; there is "
                    "no profiling and no automated decision with legal effect.",
                    "**Health-related answers:** Areas to protect are your own "
                    "preference. They are not a medical record, and we do not "
                    "diagnose or assess anything.",
                ]),
                ("h3", "B. Workouts & Progress"),
                ("ul", [
                    "**What We Collect:** Workouts you finish or add by hand (name, "
                    "date, length, exercises), how far you got in a workout you "
                    "left early, how a set felt (Easy / Just right / Hard), "
                    "favorites, personal records, plank results, and app settings "
                    "such as your reminder time, theme and music choice.",
                    "**Why We Collect It:** To show your streak, achievements, "
                    "calendar and history, to let you resume a workout, and to "
                    "set your reminders.",
                ]),
                ("h3", "C. Account & Authentication (Optional)"),
                ("ul", [
                    "**What We Collect:** If you create an account: your email "
                    "address, the display name you give, and how you sign in "
                    "(email and password, Google, or Apple). With Apple you may "
                    "hide your email; we then receive Apple's private relay "
                    "address. Your password is handled by Firebase "
                    "Authentication; we never see it.",
                    "**Why We Collect It:** To secure your account and to save "
                    "your plan and progress so they come back when you sign in "
                    "on another phone.",
                ]),
                ("h3", "D. Subscriptions, In-App Purchases & Billing"),
                ("ul", [
                    "**Apple App Store & Google Play Billing:** When you buy "
                    "Premium, the payment is processed by Apple or Google. "
                    "Calesthetics does **not** collect, store, or have access to "
                    "your card number, bank details, or billing address.",
                    "**Subscription Infrastructure (RevenueCat):** We use "
                    "RevenueCat to check and manage subscriptions. It receives "
                    "purchase receipts, purchase and renewal dates, your "
                    "subscription status, and an app user ID (your account ID, or "
                    "an anonymous one for a guest), only to confirm what you have "
                    "bought and unlock Premium on your devices.",
                ]),
                ("h3", "E. Technical Data"),
                ("ul", [
                    "Like any app that uses the internet, the services below see "
                    "your IP address and basic device and request information when "
                    "the app talks to them: Google (Firebase) when you sign in or "
                    "sync, and our media provider Bunny.net when exercise videos "
                    "and pictures load.",
                    "**We do not use** advertising IDs, analytics or "
                    "crash-reporting tools, and we do not track you across other "
                    "apps or websites.",
                ]),
            ],
        },
        {
            "title": "Strict Zero Third-Party Sharing Policy",
            "blocks": [
                ("p", "We keep a strict standard:"),
                ("ul", [
                    "**No Data Monetization:** We do not sell, rent, license, or "
                    "barter your personal information or training data, ever.",
                    "**No Advertising Trackers:** We do not include third-party "
                    "advertising SDKs, cross-app tracking libraries, or marketing "
                    "pixels.",
                    "**No AI Processing of Your Data:** We do not send anything "
                    "you enter or do in the app to an AI service. The exercise "
                    "videos and pictures were made in advance with AI tools "
                    "(Google Flow) and ship as fixed content.",
                    "**Trusted Service Providers:** We use these providers only "
                    "to run the app, each acting on our instructions: **Google** "
                    "(Firebase Authentication, Cloud Firestore and Google "
                    "Sign-In: accounts and your synced data), **Apple** (Sign in "
                    "with Apple and the App Store), **Google Play** (billing on "
                    "Android), **RevenueCat** (subscription status), and "
                    "**Bunny.net** (delivery of exercise videos and pictures). "
                    "They may not use your data for anything else.",
                    "**Legal and Safety:** We may disclose information if the law "
                    "requires it, or to protect the app and its users from fraud "
                    "or abuse. If Verado Studio is ever sold or merged, this "
                    "policy keeps applying to your data.",
                ]),
            ],
        },
        {
            "title": "How Your Data Is Stored: Guest or Account",
            "blocks": [
                ("ul", [
                    "**Guest:** Your plan, progress and settings are stored only "
                    "on your phone. Nothing is uploaded. Deleting the app, "
                    "clearing its data, or using **Profile > Erase data on this "
                    "phone** erases them.",
                    "**Account:** Your data is saved in one private record that "
                    "belongs to your account (Google Cloud Firestore), protected "
                    "by security rules so that only you, signed in, can read or "
                    "change it. Changes sync a few seconds after you make them.",
                    "**Creating an account** keeps what you already did as a "
                    "guest. **Signing in to an existing account** shows that "
                    "account's own data on the phone instead.",
                    "**Signing out** removes your data from the phone. It stays "
                    "in your account, ready for your next sign-in.",
                ]),
            ],
        },
        {
            "title": "Device Permissions & Data Access",
            "blocks": [
                ("p", "Calesthetics asks only for what its features need:"),
                ("ul", [
                    "**Notifications:** Used only for the workout reminders you "
                    "switch on. They are scheduled on your phone itself; there is "
                    "no push-notification server, and you can turn them off "
                    "anytime in the app or in system settings.",
                    "**Vibration:** Used for the light haptic feedback while you "
                    "use the app. It needs no data.",
                    "**Share sheet:** When you tap Share on an achievement, the "
                    "app hands a picture of that achievement card and one line of "
                    "text to your phone's share sheet. Nothing is sent unless you "
                    "choose where to share it.",
                    "**Not requested:** camera, photo library, microphone, "
                    "location, contacts, or health data (such as Apple Health or "
                    "Google Fit).",
                ]),
            ],
        },
        {
            "title": "User Rights, Data Control & Account Deletion",
            "blocks": [
                ("p", "In line with **Apple App Store Review Guideline 5.1.1**, "
                      "the **Google Play User Data policy**, and privacy laws "
                      "such as the GDPR and the CCPA/CPRA, you stay in control:"),
                ("ul", [
                    "**In the app:** You can change your name, switch reminders "
                    "off, sign out, or delete your account yourself.",
                    "**Complete Account Erasure:** You can permanently erase your "
                    "account and everything saved in it, directly in the app:",
                ]),
                ("code", "Profile > Delete Account"),
                ("p", "When you confirm, your account record is deleted from our "
                      "servers, your sign-in account is deleted, and the data is "
                      "cleared from your phone. If your last sign-in was a while "
                      "ago, you may first be asked to confirm that it is you "
                      "(with Google, Apple or your password). On iPhone, the "
                      "app's Sign in with Apple access is also revoked."),
                ("p", "**Without an account (guest):** nothing is stored on our "
                      "servers, so there is no account to delete. To clear what "
                      "is saved on your phone (plan, history, favorites and "
                      "settings), use **Profile > Erase data on this phone**. "
                      "If you bought Premium on that phone, use Restore "
                      "purchases afterwards to get it back."),
                ("ul", [
                    "**Subscription Cancellation Reminder:** Deleting your "
                    "account does **not** cancel an active Apple or Google "
                    "subscription. Cancel it in your Apple ID or Google Play "
                    "subscription settings.",
                    "**Your rights:** Depending on where you live (for example "
                    "the EU, the UK, or California) you may ask us for access to "
                    "your data, to correct it, to delete it, to receive a copy "
                    "(portability), to restrict or object to its use, and to "
                    "complain to your data-protection authority. We do not sell "
                    "or share your data for advertising, and we do not treat you "
                    "differently for using these rights.",
                    "**How to ask:** Email [[email]]. We reply to privacy "
                    "requests within 30 days.",
                    "**Legal bases (GDPR):** We use your data to provide the app "
                    "you asked for (contract), to keep it secure (legitimate "
                    "interest), and, for optional things like reminders, with "
                    "your consent, which you can withdraw anytime.",
                ]),
            ],
        },
        {
            "title": "Security & Data Retention",
            "blocks": [
                ("p", "All communication between the app and our servers is "
                      "encrypted in transit (HTTPS/TLS). Account data is stored "
                      "with Google Cloud, which encrypts it at rest, behind "
                      "security rules that let only the signed-in owner read or "
                      "change their own record. No system is perfectly secure, "
                      "but we work to protect your data."),
                ("p", "We keep your data **only as long as your account exists.** "
                      "When you delete it, your record is removed from our "
                      "servers right away; copies in the provider's backups are "
                      "overwritten on their normal schedule. Guest data stays on "
                      "your phone until you delete the app or clear its data. "
                      "Emails you send to support are kept only as long as "
                      "needed to help you."),
            ],
        },
        {
            "title": "Mandatory Non-Medical Disclaimer",
            "blocks": [
                ("warn", "⚠️ Training Guidance — Not Medical Advice",
                 "Calesthetics is a fitness and training app. It is **not** a "
                 "medical device and does **not** provide medical diagnoses, "
                 "treatment or clinical advice. The \"areas to protect\" you "
                 "choose only change which exercises are suggested; they are not "
                 "a medical assessment. Talk to a doctor before you start if you "
                 "have an injury, a health condition, or are pregnant, and stop "
                 "right away if anything hurts."),
            ],
        },
        {
            "title": "Children's Privacy",
            "blocks": [
                ("p", "Calesthetics is intended for adults aged 18 and over and is "
                      "not directed at children. We do not knowingly collect "
                      "personal data from anyone under 13 (or under 16 in the "
                      "European Union). If you believe a child has given us "
                      "information, contact us and we will delete it promptly."),
            ],
        },
        {
            "title": "International Data Transfers",
            "blocks": [
                ("p", "Our providers (Google, RevenueCat, Bunny.net, Apple) run "
                      "servers in several countries, including outside your own, "
                      "such as the United States and the European Union. By "
                      "using an account you understand that your data may be "
                      "processed there, under the safeguards those providers "
                      "offer, such as standard contractual clauses."),
            ],
        },
        {
            "title": "Changes to This Privacy Policy",
            "blocks": [
                ("p", "We may update this Privacy Policy when the app, its "
                      "features or the law change. The new version is posted here "
                      "with an updated \"Last Updated\" date, and the in-app copy "
                      "is updated with it. Continuing to use Calesthetics after a "
                      "change means you accept the updated policy. See also our "
                      "[[terms]]."),
            ],
        },
        {
            "title": "Contact Information",
            "blocks": [
                ("p", "For privacy questions, data requests, or anything about "
                      "how we handle your data, please contact us:"),
                ("contact", [
                    ("Application", APP),
                    ("Publisher", PUBLISHER),
                    ("Support Email", "[[email]]"),
                ]),
            ],
        },
    ],
}

# ------------------------------------------------------------------ terms ---
TERMS = {
    "title": "Terms of Service",
    "badge": "Official Policy Document",
    "box": (
        "\U0001F4CB",
        "The Key Points",
        "**Calesthetics is free with one training plan.** **Premium** unlocks "
        "every plan and every exercise: **$9.99 per month** (with a **7-day "
        "free trial** for new subscribers) or **$49.99 per year**. Subscriptions "
        "renew automatically until you cancel in your Apple or Google "
        "subscription settings. Train within your own limits: this app is "
        "training guidance, not medical advice.",
    ),
    "sections": [
        {
            "title": "Agreement to These Terms",
            "blocks": [
                ("p", "These Terms of Service (also called Terms of Use) are an "
                      "agreement between you and **Verado Studio** (\"we\", \"us\") "
                      "for the Calesthetics app. By installing or using the app "
                      "you agree to them and to our [[privacy]]. If you do not "
                      "agree, please do not use the app."),
                ("p", "The app is for adults. You must be 18 or older, or the age "
                      "of majority where you live."),
            ],
        },
        {
            "title": "Health, Safety & Not Medical Advice",
            "blocks": [
                ("warn", "⚠️ Train Within Your Own Limits",
                 "Calesthetics provides general training guidance. It is **not** "
                 "medical advice and not a substitute for a doctor or qualified "
                 "coach. Talk to a doctor before you start if you have an "
                 "injury, a health condition, or are pregnant. Stop right away "
                 "if you feel pain, dizziness or anything unusual. **You use the "
                 "app and do the exercises at your own risk.** The \"areas to "
                 "protect\" you choose only change which exercises are "
                 "suggested; they are not a medical assessment, and no plan can "
                 "promise a result."),
            ],
        },
        {
            "title": "Your Account",
            "blocks": [
                ("ul", [
                    "**Optional:** You can use the app as a guest. An account "
                    "(email, Google or Apple) saves your plan and progress so "
                    "they follow you to a new phone.",
                    "**Keep it safe:** You are responsible for your sign-in "
                    "details and for what happens under your account. Give us "
                    "accurate information and tell us if you think someone "
                    "else is using your account.",
                    "**Delete it anytime:** In the app, go to **Profile > Delete "
                    "Account**. This erases your account and its data (see our "
                    "[[privacy]]). As a guest, **Profile > Erase data on this "
                    "phone** clears what is saved on your phone.",
                ]),
            ],
        },
        {
            "title": "Free and Premium",
            "blocks": [
                ("ul", [
                    "**Free:** One training plan, and the exercise videos in "
                    "that plan.",
                    "**Premium:** Every plan, and every exercise and video in "
                    "Discover. Premium may include other features we add later.",
                    "We may change, add or remove features, and the line between "
                    "Free and Premium, as the app develops. We will not take "
                    "away what you have already paid for during the period you "
                    "paid for.",
                ]),
            ],
        },
        {
            "title": "Subscriptions, Free Trial & Billing",
            "blocks": [
                ("h3", "A. Prices and Free Trial"),
                ("ul", [
                    "**Monthly:** $9.99 per month, with a **7-day free trial** "
                    "for eligible new subscribers. **Yearly:** $49.99 per year "
                    "(no trial).",
                    "Prices can differ by country and include taxes where "
                    "required; the exact price is shown in the store before you "
                    "confirm. The free trial is offered once per person. "
                    "Any unused part of a free trial ends when you buy a "
                    "subscription.",
                ]),
                ("h3", "B. Billing and Renewal"),
                ("ul", [
                    "Payment is charged to your Apple ID or Google Play account "
                    "when you confirm the purchase (or when the free trial "
                    "ends).",
                    "Subscriptions **renew automatically** for the same period "
                    "unless you cancel at least **24 hours** before the current "
                    "period ends. Your account is charged for the renewal within "
                    "24 hours before it ends.",
                ]),
                ("h3", "C. Cancelling, Refunds and Restoring"),
                ("ul", [
                    "Manage or cancel in your **Apple ID > Subscriptions** or "
                    "**Google Play > Payments & subscriptions** settings. "
                    "Deleting the app or your Calesthetics account does **not** "
                    "cancel a subscription.",
                    "Apple and Google handle payments and refunds, and their "
                    "rules apply. We cannot refund purchases made through them.",
                    "On a new phone, use **Restore** on the Premium screen to "
                    "bring your subscription back.",
                ]),
            ],
        },
        {
            "title": "Using the App",
            "blocks": [
                ("p", "You may use Calesthetics for your own personal, "
                      "non-commercial training. You agree not to:"),
                ("ul", [
                    "copy, record, download in bulk, resell or share the videos, "
                    "pictures, plans or text outside the app (other than what "
                    "the app's Share button offers);",
                    "reverse engineer, modify, or try to break or bypass the app, "
                    "its sign-in, or its Premium protection;",
                    "overload or interfere with our services, or use the app in "
                    "a way that breaks the law.",
                ]),
            ],
        },
        {
            "title": "Content and Ownership",
            "blocks": [
                ("ul", [
                    "**Ours:** The app, its design, exercise videos, pictures, "
                    "plans and text belong to Verado Studio or its licensors. "
                    "We give you a limited, personal, non-exclusive, "
                    "non-transferable, revocable license to use the app.",
                    "**AI-generated media:** The exercise videos and pictures "
                    "were created with AI tools (Google Flow). The people and "
                    "places in them are AI-generated, not real athletes. They "
                    "show how a move is meant to look: follow the written "
                    "steps and cues, and stop if anything hurts.",
                    "**Yours:** What you enter (your name, answers, activities, "
                    "favorites) stays yours. You allow us to store and process "
                    "it only to run the app for you, as the [[privacy]] "
                    "describes.",
                    "**Feedback:** If you send us ideas, we may use them without "
                    "owing you anything.",
                    *CREDIT_ITEMS,
                ]),
            ],
        },
        {
            "title": "Third-Party Services and App Stores",
            "blocks": [
                ("p", "The app relies on services from Google (Firebase, Google "
                      "Sign-In, Google Play), Apple (Sign in with Apple, App "
                      "Store), RevenueCat and Bunny.net. Their own terms apply "
                      "to their parts. Apple and Google are not responsible for "
                      "the app or for supporting it; we are. If you got the app "
                      "from the App Store, Apple's standard end-user terms also "
                      "apply, and Apple is a third-party beneficiary of these "
                      "terms for that purpose."),
            ],
        },
        {
            "title": "Availability and Changes",
            "blocks": [
                ("p", "We work to keep the app running, but we cannot promise it "
                      "will always be available, error-free or work offline for "
                      "every feature (videos you have not played yet need the "
                      "internet). We may update, change or stop parts of the app "
                      "at any time."),
            ],
        },
        {
            "title": "Ending Your Use",
            "blocks": [
                ("p", "You can stop using the app at any time and delete your "
                      "account in **Profile > Delete Account** (as a guest: "
                      "**Profile > Erase data on this phone**). We may suspend "
                      "or end access if you seriously or repeatedly break these "
                      "terms or misuse the app. Anything that by its nature "
                      "should continue (such as ownership and liability limits) "
                      "does. A paid subscription continues until you cancel it "
                      "in the store."),
            ],
        },
        {
            "title": "Disclaimers and Limit of Liability",
            "blocks": [
                ("p", "The app is provided **\"as is\" and \"as available\"**. To "
                      "the fullest extent the law allows, we do not promise "
                      "specific results (strength, skills or fitness) and we are "
                      "not liable for indirect or consequential loss, or for "
                      "injury or loss that comes from exercising or from not "
                      "following the safety advice above. Our total liability "
                      "for any claim about the app is limited to the amount you "
                      "paid us in the 12 months before it."),
                ("p", "Nothing in these terms limits liability that cannot be "
                      "limited by law, or the consumer rights you have where you "
                      "live."),
            ],
        },
        {
            "title": "Governing Law",
            "blocks": [
                ("p", "These terms are governed by the laws that apply where "
                      "Verado Studio is established, without removing any "
                      "mandatory consumer protection you have in your own "
                      "country. If you have a concern, please write to us first "
                      "at [[email]]; we will try to sort it out fairly and "
                      "quickly."),
            ],
        },
        {
            "title": "Changes to These Terms",
            "blocks": [
                ("p", "We may update these terms. The new version is posted here "
                      "with an updated \"Last Updated\" date, and in the app. "
                      "If you keep using Calesthetics after a change, you accept "
                      "the new terms. If you do not agree, stop using the app "
                      "and delete your account."),
            ],
        },
        {
            "title": "Contact Information",
            "blocks": [
                ("p", "Questions about these terms? Contact us:"),
                ("contact", [
                    ("Application", APP),
                    ("Publisher", PUBLISHER),
                    ("Support Email", "[[email]]"),
                ]),
            ],
        },
    ],
}

# ---------------------------------------------------------------- support ---
SUPPORT = {
    "title": "Help & Support",
    "badge": "Help Center",
    "show_dates": False,
    "box": (
        "\U0001F4AC",
        "We are here to help",
        "Most answers are on this page, so look here first: it is the fastest "
        "way to get unstuck. If you cannot find yours, email **[[email]]**. "
        "We read every message and reply by email.",
    ),
    "sections": [
        {
            "title": "Getting Started",
            "blocks": [
                ("h3", "How do the plans work?"),
                ("p", "Your plan is split into phases of three training days. "
                      "Each day lists a warm-up, the main exercises and a "
                      "cool-down. Open a day and tap **START**."),
                ("h3", "Why is a day locked?"),
                ("p", "Days open one after another: finish a day to unlock the "
                      "next. It keeps your progression steady and safe."),
                ("h3", "I quit in the middle of a workout. Is it lost?"),
                ("p", "No. Quitting saves how far you got. Open that day again "
                      "and tap **Resume** to carry on from where you stopped."),
                ("h3", "Can I change my plan?"),
                ("p", "Yes. On the Plan tab, tap **Edit** to adjust your "
                      "training, or open the plan menu at the top to see all "
                      "plans and switch. Switching asks you to confirm first. "
                      "Free includes one plan; Premium lets you add more."),
            ],
        },
        {
            "title": "Your Account and Signing In",
            "blocks": [
                ("h3", "Do I need an account?"),
                ("p", "No, you can use the app as a guest. An account (email, "
                      "Google, or Apple on iPhone) saves your plan and "
                      "progress so they follow you to a new phone."),
                ("h3", "I have a new phone. How do I get my progress back?"),
                ("p", "Sign in with the same account. Your plan, history, "
                      "favorites and settings come back. If you use Premium, "
                      "also tap **Restore purchases** (see below). Guest data "
                      "lives only on the old phone, so it cannot be moved."),
                ("h3", "I cannot sign in."),
                ("ul", [
                    "Check your internet connection and try again.",
                    "With Google: make sure a Google account is added to your "
                    "phone.",
                    "With email: tap **Forgot password?** on the sign-in sheet "
                    "and we will email you a link to choose a new one.",
                    "Still stuck? Email us (see the end of this page).",
                ]),
                ("h3", "How do I change my name?"),
                ("p", "Open **Profile** and tap the pencil at the top of your "
                      "card."),
            ],
        },
        {
            "title": "Premium and Subscriptions",
            "blocks": [
                ("h3", "What does Premium include?"),
                ("p", "Every plan, and every exercise and video in Discover. "
                      "**Monthly** is $9.99 per month with a **7-day free "
                      "trial** for eligible new subscribers; **Yearly** is "
                      "$49.99 per year. The free trial is offered once per "
                      "person."),
                ("h3", "I paid, but Premium is not showing."),
                ("ul", [
                    "Open **Profile**, tap **Manage** on the Premium card, then "
                    "**Restore purchases**. You can also tap **Restore** on the "
                    "Premium screen.",
                    "Use the same Apple ID or Google account that bought it.",
                    "Still missing? Email us the order number from your Apple "
                    "or Google receipt and we will help.",
                ]),
                ("h3", "How do I cancel?"),
                ("p", "Cancel in the store, not in the app: **Apple ID > "
                      "Subscriptions** on iPhone, or **Google Play > Payments "
                      "& subscriptions > Subscriptions** on Android. Cancel at "
                      "least 24 hours before it renews. Deleting the app or "
                      "your Calesthetics account does **not** cancel it."),
                ("h3", "Can I get a refund?"),
                ("p", "Apple and Google take the payment, so they handle "
                      "refunds. On iPhone, use reportaproblem.apple.com; on "
                      "Android, use your order history in Google Play. We "
                      "cannot refund purchases made through them."),
            ],
        },
        {
            "title": "Workouts, Videos and Music",
            "blocks": [
                ("h3", "A video will not load."),
                ("p", "Videos stream from the internet the first time you "
                      "play them, so check your connection. After the first "
                      "play, a video is saved on your phone and works offline."),
                ("h3", "How do I free up space?"),
                ("p", "Open **Profile > Downloaded videos > Clear**. Videos "
                      "download again the next time they play."),
                ("h3", "How do I change the music?"),
                ("p", "Tap the music button at the top right of a workout (or "
                      "of a day's preview). Switch **Music** on or off and "
                      "slide the volume. This changes only the background "
                      "music, never the coach's voice in the videos."),
                ("h3", "Are the people in the videos real?"),
                ("p", "No. The videos and pictures were made with AI tools "
                      "(Google Flow), so the coach you see is AI-generated. "
                      "They show how a move is meant to look: follow the "
                      "written cues, and stop if anything hurts."),
                *(
                    [("h3", "Where does the music come from?"),
                     ("p", "Credits are in our [[terms]]: " + MUSIC_CREDIT)]
                    if MUSIC_CREDIT else []
                ),
                ("h3", "I cannot hear the coach."),
                ("p", "Check that your phone is not on silent and that the "
                      "media volume is up. The music switch does not affect "
                      "the coach's voice."),
            ],
        },
        {
            "title": "Reminders",
            "blocks": [
                ("h3", "How do I turn on reminders?"),
                ("p", "Open **Profile > Reminders**, switch them on and pick a "
                      "time. We remind you on the days your plan trains. Allow "
                      "notifications when your phone asks."),
                ("h3", "My reminders do not arrive."),
                ("ul", [
                    "In your phone's settings, make sure notifications are "
                    "allowed for Calesthetics.",
                    "On some Android phones, battery saver can delay or block "
                    "reminders. Set Calesthetics to **Unrestricted** (or remove "
                    "its battery limits).",
                    "Reminders are scheduled on your phone, so they work "
                    "without internet.",
                ]),
            ],
        },
        {
            "title": "Your Data and Privacy",
            "blocks": [
                ("h3", "How do I delete my account?"),
                ("p", "Signed in: open **Profile > Delete Account**. We may "
                      "first ask you to confirm it is you. As a guest, **Profile "
                      "> Erase data on this phone** clears everything saved on "
                      "your phone. Neither one cancels a subscription."),
                ("h3", "What do you do with my data?"),
                ("p", "We do not sell or share it. Read the details in our "
                      "[[privacy]] and our [[terms]]."),
            ],
        },
        {
            "title": "Still Need Help?",
            "blocks": [
                ("p", "Email us and include, if you can: what happened and what "
                      "you expected; your phone model and its system version; "
                      "the app version (at the bottom of your Profile screen); "
                      "and a screenshot. Please never send your password."),
                ("contact", [
                    ("Application", APP),
                    ("Publisher", PUBLISHER),
                    ("Support Email", "[[email]]"),
                ]),
            ],
        },
    ],
}
