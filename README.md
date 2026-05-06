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

## iOS WidgetKit setup (one-time, in Xcode)

The Swift source for the home-screen widget lives in `ios/MyPrayersWidget/`. Adding the extension target itself must be done once in Xcode:

1. `cd ios && pod install`
   - If pod install fails with `Unable to find compatibility version string for object version 70`, your CocoaPods is too old for Xcode 16. Run `sudo gem install cocoapods` (or `brew upgrade cocoapods`) and retry. Xcode 16 generates `objectVersion = 70`; only `xcodeproj >= 1.28` understands it.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. **File → New → Target**, choose **Widget Extension**, name it `MyPrayersWidget`. Untick "Include Configuration Intent" (we ship our own `PrayersWidgetConfigurationIntent.swift`). Untick "Include Live Activity".
4. When Xcode creates the target, **delete** the auto-generated `MyPrayersWidget.swift` and any auto-generated `Info.plist` and entitlements — replace them with the ones already on disk in `ios/MyPrayersWidget/`.
5. In the new target's **Build Phases → Compile Sources**, add:
   - `MyPrayersWidget.swift`
   - `PrayersWidgetConfigurationIntent.swift`
6. In **Build Phases → Copy Bundle Resources**, add `AmiriQuran-Regular.ttf` (already in `ios/MyPrayersWidget/`).
7. In the new target's **Signing & Capabilities**, add:
   - **App Groups** capability with group `group.com.shkomaghdid.myprayers`
   - Same App Group on the **Runner** target (entitlements file is already at `ios/Runner/Runner.entitlements`)
8. Set **Deployment Target = iOS 17.0** on the widget target.
9. In the **Runner** target's **Info.plist**, the App Groups entitlement is already declared; just make sure Xcode picks up `Runner.entitlements` under the Runner target's **Code Signing Entitlements** build setting.

After that, build & run normally; the widget shows up in the iOS widget gallery as **My Prayers**.

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
