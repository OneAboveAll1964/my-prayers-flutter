# My Prayers — Flutter

Mobile (iOS + Android) port of [my-prayers-web](https://github.com/OneAboveAll1964/my-prayers-web), itself a port of [@shkomaghdid/react-native-prayer-times](https://github.com/OneAboveAll1964/react-native-prayer-times).

Fully offline. The `muslim_db_v3.0.0.db` (~28 MB) and all 114 surahs in 3 editions (~8.5 MB) are bundled in `assets/`.

## Stack

- Flutter 3.41 / Dart 3.11
- Riverpod for state
- sqflite for the bundled DB
- `flutter_local_notifications` + bundled adhan audio
- `home_widget` for home-screen widgets (iOS WidgetKit, Android AppWidget)
- Native widget targets in Swift (iOS) and Kotlin (Android)

## Run

```bash
flutter pub get
flutter run
```

Android targets `compileSdk` from Flutter's pinned version, `minSdk = 24`. iOS targets the iOS 17 SDK (required by WidgetKit's `AppIntentConfiguration`).

## Bundle ID

`com.shkomaghdid.myprayers` for both platforms.

## iOS WidgetKit setup

The widget is **fully self-contained** — no App Groups, no shared UserDefaults, no paid Apple Developer account needed. The widget extension picks an ayah/azkar deterministically from a bundled list using the current date+hour as the seed (so each refresh shows a different verse, but the same one for everyone configuring it the same way at the same hour).

The Swift source for the widget lives in `ios/MyPrayersWidget/`:

- `MyPrayersWidget.swift` — TimelineProvider, view, and `@main WidgetBundle` entry
- `PrayersWidgetConfigurationIntent.swift` — AppIntent with the user-facing options (type / theme / size / language / show translation / refresh interval)

**One-time Xcode steps if you are setting this up fresh** (already wired in this repo):

1. `cd ios && pod install`
   - If pod install fails with `Unable to find compatibility version string for object version 70`, this is a known unresolved CocoaPods/xcodeproj bug — even CocoaPods 1.16.2 still ships `xcodeproj 1.27.0`, which doesn't recognize Xcode 16's project format. Workaround: open `ios/Runner.xcodeproj/project.pbxproj` and change `objectVersion = 70;` to `objectVersion = 60;`. CocoaPods reads it and Xcode 16 still loads it fine. (Xcode may bump it back to 70 if you make a UI change that needs new features; just change it back if it does.)
   - On macOS, install the latest CocoaPods via Homebrew: `brew install cocoapods`. The Homebrew binary lives at `/usr/local/opt/cocoapods/bin/pod` — invoke it directly to bypass any rbenv/system shim that's pinned to an older version.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. **File → New → Target**, choose **Widget Extension**, name it `MyPrayersWidget`. Untick "Include Live Activity". Tick "Include Configuration Intent" — Xcode will scaffold an intent file you can immediately delete (we ship our own).
4. After the target is created, in the Project Navigator delete the Xcode-generated `MyPrayersWidgetBundle.swift` and `MyPrayersWidgetControl.swift` — they conflict with our `@main` and we don't ship a Control widget.
5. The synchronized folder in Xcode 16 will auto-pick up `MyPrayersWidget.swift` and `PrayersWidgetConfigurationIntent.swift` from disk; you don't need to add them manually.
6. Set **Deployment Target = iOS 17.0** on the widget target (required by `AppIntentConfiguration`).
7. In the widget target's **Build Settings**:
   - Set `Code Signing Entitlements` to **empty** (we don't use App Groups)
   - Set `Info.plist File` to **empty** (the synchronized folder + `GENERATE_INFOPLIST_FILE = YES` produces a valid widget Info.plist on its own)
   - Bundle ID: `com.shkomaghdid.myprayers.MyPrayersWidget`
8. **Signing & Capabilities** on the widget target: pick your Personal Team. Do **not** add the App Groups capability — it's not available on free dev accounts and the widget doesn't need it.

The widget appears in the iOS widget gallery as **My Prayers**. Long-press it to enter the configuration screen with all six options.

### What App Groups would unlock (optional, paid account)

If you ever upgrade to a paid Apple Developer Program, you can add the **App Groups** capability with group `group.com.shkomaghdid.myprayers` to *both* the Runner and the Widget targets, and the app will be able to push specific verses (e.g., the user's bookmarked ayah) to the widget at runtime. Without App Groups, the widget still cycles through the bundled curated list — which is the design we shipped.

## Android home-screen widget

Already wired. The widget shows up as **My Prayers** in the Android home-screen widget picker. Long-press the home screen, search "My Prayers", drop it on the screen, and the configuration activity (in `android/app/src/main/kotlin/.../widget/WidgetConfigActivity.kt`) opens for type / theme / size / show-translation / randomize.

## Notifications

`assets/audio/adhan.mp3` is a 28-second CC0 adhan recording (Ahmed al-Imadi, Internet Archive Public Domain Mark). It's converted to `ios/Runner/adhan.caf` for iOS and copied to `android/app/src/main/res/raw/adhan.mp3` for Android. iOS notification sounds cap at 30 seconds; the file is well under that.

To swap the adhan: replace those two files with your own and re-run the build. Keep the file names exactly as `adhan.mp3` (Android) and `adhan.caf` (iOS).

## Architecture

```
lib/
├── core/
│   ├── i18n/        # 4 language bundles (en, ar, ckb, ckb_Badini)
│   ├── router/      # go_router config
│   ├── services/    # NotificationService, WidgetDataService
│   ├── theme/       # AppPalette extension + light/dark themes
│   └── utils/       # date / hijri / qibla
├── features/
│   ├── prayer_times/    # CalculatedPrayerTime - 1:1 port of the JS engine
│   ├── home/            # Home page + widgets (DateBar, PrayerCard, etc.)
│   ├── azkars/          # Categories -> Chapters -> Items + dhikr counter
│   ├── qibla/           # Live compass with bearing + distance
│   ├── quran/           # Surah list + per-surah reader (with last-read tracking)
│   ├── calendar/        # Monthly grid
│   ├── names/           # 99 Names
│   ├── tasbih/          # Counter with target presets
│   ├── settings/        # Settings + sub-pages (language, location, method)
│   ├── shell/           # AppShell + bottom tab bar + More sheet
│   └── home_widget/     # Shared text data for native home-screen widgets
└── shared/
    ├── data/    # MuslimDb, Location/Name/Hisnul/PrayerTime/Quran repositories
    ├── models/  # Domain types
    ├── state/   # Riverpod stores (settings, favorites)
    └── widgets/ # UI primitives (Button, Field, Sheet, Toggle, etc.)
```

## Continue-reading fix

The web version had a known bug where "Continue reading" always opened the surah at ayah 1. This Flutter port fixes it by:

- Tracking the topmost visible ayah while reading (via `RenderBox.localToGlobal` on a per-ayah `GlobalKey`)
- Persisting `lastAyah` as part of `LastReadEntry` (Riverpod `favoritesProvider`)
- Wiring "Continue reading" to navigate to `/quran/{n}?ayah={lastAyah}` and scroll to that ayah on load

The same fix has been backported to the web app (see `pages/Surah.jsx` and `components/Quran/LastReadCard.jsx` there).
