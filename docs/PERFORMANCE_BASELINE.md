# Performance Baseline — Phase 1

Captured before any Phase 2+ changes, so later phases have a before/after to compare against.

## Measurement environment (read this first)

The brief asks for profile-mode measurement **on a real iPhone (iPhone 11/12 floor)**.
This session's environment is Linux with no Xcode/Mac access, so iPhone measurement
wasn't possible. Everything below is from the **wireless Android device already used
throughout this project** (Vivo V2043, Android 11, Flutter **profile** build —
`flutter build apk --profile`, not debug). Treat these as directional, not iOS numbers;
iOS timings should be re-captured the first time a Mac is available, before trusting
this doc as the final gate for the 2 s / 16 ms budgets.

One thing this did settle: **every "the app takes 10+ seconds to show anything" moment
from earlier in this project was a debug-build artifact** (JIT warmup, debug asserts,
unoptimized debug rendering). In profile mode the same app is fast. Don't judge future
UI work by how debug builds feel on this device — always spot-check in profile mode.

## Cold start

Measured with `adb shell am start -W` (Android's own launch-to-first-frame timer),
profile build, after `pm clear` for the very first number:

| Run | TotalTime |
|---|---|
| 1st launch after fresh install | 4947 ms |
| 2nd launch (force-stop → relaunch) | 974 ms |
| 3rd launch | 999 ms |
| 4th launch | 1027 ms |

The first-ever launch pays a one-time ART/APK-verification cost; every launch after
that is consistently **~1 s**, comfortably inside the 2 s budget. Confirmed visually
too: a screenshot taken immediately after the `am start -W` call on a warm launch
already shows full onboarding content, not a blank frame.

**Caveat:** this is Android's "first frame drawn" signal, which can fire before the
Flutter UI has meaningfully populated. The visual check above makes me confident it's
not misleading here, but it's worth re-confirming with Flutter's own
`reportFullyDrawn`-equivalent timing once real content (video thumbnails, Firebase
init) is in the critical path in later phases.

## Frame timing (PerformanceOverlay)

No `dumpsys gfxinfo` data was usable — on this device Flutter's own rendering surface
doesn't populate Android's HWUI frame stats (`Total frames rendered: 0` even after
visibly rendering hundreds of frames), so a different signal was needed. I temporarily
added `showPerformanceOverlay: true` to `MaterialApp.router` in `main.dart`, rebuilt in
profile mode, exercised the flows below, then removed it (see "Changes" below — nothing
performance-overlay-related shipped).

| Scenario | Raster (UI-visible GPU thread) | UI (Dart) thread |
|---|---|---|
| Idle, just-launched onboarding screen | max 120.8 ms, avg 1.5 ms | max 26.4 ms, avg 0.2 ms |
| Scrolling the Age grid (3 fast swipes) | max 157.5 ms, avg 13.0 ms | max 33.2 ms, avg 1.8 ms |
| Chapter step transition (list→list) | max 74.9 ms, avg 12.0 ms | max 34.8 ms, avg 2.0 ms |

Pattern across all three: a short burst of tall bars right at the moment of
first-ever-render of a given screen/transition (new shaders/layouts compiling), then
the live graph flattens to a near-zero baseline for the rest of the interaction. The
"max" column is dominated by that one-time burst, not sustained jank — the **averages
or near-zero steady-state bars** are the number to trust, and they're well inside the
16 ms/60 Hz budget (8.3 ms ProMotion budget is tighter and not yet verified — needs an
actual ProMotion/120 Hz device, i.e. a real iPhone, to confirm).

**Takeaway:** steady-state onboarding performance (scrolling, selecting, transitioning)
is good. The thing worth optimizing later is the one-time compile spike on first use of
a screen — standard Flutter/Skia shader-compilation jank, addressed by warming up
shaders or by Impeller (check the project's Impeller status when the iOS target is
buildable).

## Idle memory

`adb shell dumpsys meminfo com.veradostudio.calisthenics`, idle on an onboarding
choice screen: **~176 MB PSS total** (Native heap 16.7 MB, GL mtrack 73 MB — the
largest single contributor, likely the gradient `MediaPlaceholder` surfaces and Skia
compositing layers). No video playback exists yet (Phase 5), so there's no
10-workout memory-growth number yet — that check needs to be repeated once the
workout player has real video.

## Code review — the brief's "known suspects"

| Suspect | Found? | Where |
|---|---|---|
| `IntrinsicHeight` in list-choice tiles | **Yes**, 2 places | `choice_list_tile.dart`, `milestones_step_content.dart` — both added this session for the full-bleed-image card redesign. `IntrinsicHeight` forces a double layout pass; fine for 4-6 items, worth a non-`IntrinsicHeight` alternative (e.g. a fixed-ratio image column instead of "stretch to match text's intrinsic height") if any list grows large later. |
| `GridView(shrinkWrap: true)` inside scroll views | **Yes**, 3 places | `choice_step_content.dart` (Age/Fitness-profile grids), `plan_preview_step_view.dart`, `training_screen.dart`. All bounded to small, fixed item counts (4-8), so the eager-layout cost `shrinkWrap` forces is small today — re-check if any of these ever becomes a long/dynamic list (e.g. the Discover tab's exercise grid in Phase 7, which will NOT be a small fixed count). |
| `Opacity` instead of `FadeTransition` | **Yes**, 6 places | `rise_motion.dart` (the shared `RiseFadeSlide` entrance primitive, used all over onboarding + Home), `milestones_step_content.dart`, `curve_step_content.dart`, `name_step_content.dart`, `reveal_step_view.dart` (×2). All are one-shot entrance animations over fairly small subtrees (text/cards, not full-screen video), so the `saveLayer` cost `Opacity` forces is likely negligible in practice — the overlay data above doesn't show sustained jank from these. Flagging for awareness, not treating as confirmed-bad without profiling evidence it's actually costly. |
| Missing `RepaintBoundary` | **Yes** — zero usages anywhere in `lib/` | Most notable case: `premium_bottom_nav.dart`'s `AnimatedBuilder` wraps the indicator **and** the full row of 5 static tab icons/labels in one rebuild scope, so every drag/glide tick repaints the whole bar, not just the moving bubble. The workout timer (`_TimerText` in `workout_active_view.dart`) is already well-scoped via Riverpod `select()` (only that small widget rebuilds on each tick), so it's lower-risk, but an explicit `RepaintBoundary` there too would be cheap insurance once real video is playing behind it. |

None of these showed up as *measured* jank in the overlay data above — they're
structural risks the brief asked to check, worth fixing opportunistically during
Phase 2+ work (especially before the Discover tab's larger exercise grid and the
video-playing workout player raise the stakes), not necessarily a dedicated pass.

## Changes made in this phase

- `lib/main.dart`: temporarily added then removed `showPerformanceOverlay: true` to
  capture the frame-timing data above. Net diff: **none** (file matches pre-phase
  state) — confirmed via `flutter analyze` and `flutter test` after reverting.
- Created this file.

No other source files changed. Phase 1 is observation-only by design; the findings
above (especially the `RepaintBoundary`/`IntrinsicHeight` notes) are inputs to Phase 2's
folder-restructure work, not fixed here.

## `flutter analyze` / `flutter test`

Both clean:
```
Analyzing calisthenics...
No issues found!

00:00 +1: All tests passed!
```
(Single existing test: `test/widget_test.dart`, boots to the onboarding welcome
screen. Ground rule 8's "all tests pass" is trivially true today — Phase 4's exercise
catalog is where real test coverage starts, per the brief's own spec for it.)

## Blocking questions for Phase 2

1. **iOS verification gap** — confirmed above, flagging again since it compounds:
   every later phase's "profile on device" steps will also be Android-only until a Mac
   is available. OK to keep proceeding this way per your earlier answer, just making
   sure each phase's report keeps surfacing it rather than quietly treating Android
   numbers as iOS-equivalent.
2. Phase 2 ground rule 6 (rename "Rise" → "Calesthetics") touches the **app identity**
   (`RiseApp` class, package/bundle names likely too, display name, `rise_motion.dart`
   file name, every "Rise ·" string). Should the Android `applicationId`
   (`com.veradostudio.calisthenics`) and iOS bundle ID also change, or stay as-is since
   they're already not literally "Rise"-branded? Renaming the bundle ID after any real
   users/TestFlight builds exist is disruptive, so worth confirming now rather than
   after Phase 7.
