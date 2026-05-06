# My Prayers

A clean, fully offline prayer-times and Quran companion for iOS and Android.

Bundle ID: `com.shkomaghdid.myprayers`

## Features

- **Prayer times** with 8 calculation methods, custom Fajr/Isha angles, per-prayer offsets, three high-latitude rules, and a fixed-times fallback when location is unavailable.
- **Adhan notifications** at each enabled prayer (Fajr, Dhuhr, Asr, Maghrib, Isha — Sunrise optional). Plays a 28-second CC0 adhan recording.
- **Qibla compass** with live magnetic-heading needle, distance to the Kaaba, and tap-to-recenter.
- **Quran reader** — all 114 surahs, three editions (Uthmani Arabic + English Sahih + Arabic Muyassar + Kurdish), with per-ayah continue-reading and bookmarks.
- **Hisnul Muslim azkars** with chapter index, target counter for counted dhikrs, and free-form counter for the rest.
- **Hijri calendar** in a monthly grid, today highlighted.
- **99 Names of Allah**, **Tasbih counter**, **Names index**.
- **Home-screen widgets** on both platforms — ayah, azkar, or both, with multiple background styles, layouts, sizes, themes, and translation toggles. Widgets are configurable from the long-press menu.
- **4 languages**: English, Arabic, Sorani Kurdish, Badini Kurdish. RTL throughout the Arabic and Kurdish builds.
- **Light, dark, and system themes**, with the same restrained green accent across both.
- **Fully offline** — the bundled SQLite database (~28 MB) and pre-downloaded Quran JSON (~8.5 MB) ship inside the APK/IPA. Nothing is fetched at runtime.

## Stack

- **Flutter 3.41 / Dart 3.11**
- **Riverpod** for state, **go_router** for navigation
- **sqflite** for the bundled prayer/azkar/qibla database
- **flutter_local_notifications** + **timezone** for scheduled adhan notifications
- **home_widget** + native widget targets in **Swift (WidgetKit)** and **Kotlin (AppWidget)**
- **flutter_compass** + **geolocator** for qibla and city detection

## Project layout

```
lib/
├── core/
│   ├── i18n/         4 language bundles (en, ar, ckb, ckb_Badini)
│   ├── router/       go_router config
│   ├── services/     NotificationService, WidgetDataService
│   ├── theme/        AppPalette extension + light/dark themes
│   └── utils/        date / hijri / qibla helpers
├── features/
│   ├── prayer_times/ CalculatedPrayerTime — 1:1 port of the JS engine
│   ├── home/         home page, next-prayer countdown, day strip
│   ├── azkars/       categories → chapters → items, dhikr counter
│   ├── qibla/        live compass with bearing + distance
│   ├── quran/        surah list + per-surah reader with continue-reading
│   ├── calendar/     monthly hijri grid
│   ├── names/        99 Names of Allah
│   ├── tasbih/       free-form counter with target presets
│   ├── settings/     settings + language/location/method sub-pages
│   ├── shell/        AppShell + bottom tab bar + "More" sheet
│   └── home_widget/  shared text data for native widgets
└── shared/
    ├── data/         MuslimDb + repositories (location/name/hisnul/prayer/quran)
    ├── models/       domain types
    ├── state/        Riverpod stores (settings, favorites)
    └── widgets/      UI primitives (Button, Field, Sheet, Toggle, etc.)
```

## Run

```bash
flutter pub get
flutter run                    # debug, attached device
flutter build apk --release    # release APK
flutter build ipa --release    # release IPA (requires signing)
```

Android targets `compileSdk` from Flutter's pinned version with `minSdk = 24`. iOS targets the iOS 17 SDK (required by WidgetKit's `AppIntentConfiguration`).

## Notifications

Adhan audio lives at `assets/audio/adhan.mp3` (CC0, Public Domain Mark). It is mirrored as `ios/Runner/adhan.caf` for iOS and `android/app/src/main/res/raw/adhan.mp3` for Android. iOS notification sounds cap at 30 seconds, so the file is kept under that.

To swap the adhan, replace those two files (keep the names) and rebuild.

The notification system gracefully falls back from `exactAllowWhileIdle` to `inexactAllowWhileIdle` on Android when the user has not granted the exact-alarm permission. A *Send test notification* button in Settings posts an immediate notification to confirm the channel is wired correctly.

## Home-screen widgets

### iOS

The widget bundle is fully self-contained — no App Groups, no shared UserDefaults, no paid Apple Developer account needed. It picks an ayah/azkar deterministically from a curated list using the date+hour as the seed, so the verse changes through the day.

Source: `ios/MyPrayersWidget/`

- `MyPrayersWidget.swift` — TimelineProvider, view, and `@main` widget bundle entry
- `PrayersWidgetConfigurationIntent.swift` — AppIntent with the user-facing options

Long-press the widget on the home screen to access the configuration screen.

### Android

Source: `android/app/src/main/kotlin/com/shkomaghdid/myprayers/widget/`

- `PrayersAppWidgetProvider.kt` — RemoteViews builder with theme/style/size/layout switching
- `WidgetConfigActivity.kt` — segmented configuration UI shown when the widget is added or reconfigured
- `WidgetRandomizer.kt` — picks the next verse from the bundled pool

Layouts in `res/layout/prayers_app_widget.xml` (default) and `res/layout-v31/prayers_app_widget.xml` (uses the bundled KFGQPC Hafs font on Android 12+).

The widget appears as **My Prayers** in the home-screen picker.

## Continue-reading

The web version had a long-standing bug where *Continue reading* always opened a surah at ayah 1. This port fixes it:

- Tracks the topmost visible ayah while scrolling (via `RenderBox.localToGlobal` on per-ayah `GlobalKey`s, debounced 80ms)
- Persists `lastAyah` as part of `LastReadEntry` in `favoritesProvider`
- Wires *Continue reading* to navigate to `/quran/{n}?ayah={lastAyah}` and scroll to that ayah on load

The same fix has been backported to [my-prayers-web](https://github.com/OneAboveAll1964/my-prayers-web).

## Lineage

| Repo | Role |
| --- | --- |
| [react-native-prayer-times](https://github.com/OneAboveAll1964/react-native-prayer-times) | Original React Native app |
| [my-prayers-web](https://github.com/OneAboveAll1964/my-prayers-web) | Frontend-only PWA port |
| **my-prayers-flutter** | Native iOS + Android port (this repo) |

The prayer-time engine is a faithful 1:1 port of the JavaScript original — same calculation methods, same higher-latitude logic, same offset semantics — translated into Dart.

## Credits

- **Adhan recording**: Ahmed al-Imadi, Internet Archive (Public Domain Mark / CC0)
- **KFGQPC Hafs Uthmanic Script** font: King Fahd Glorious Qur'an Printing Complex
- **muslim_db** SQLite: prayer chapters, qibla data, and city index
- **Quran translations**: en.sahih, ar.muyassar, ku.asan (via the open Quran data set)

## License

Personal project. The bundled assets (font, adhan, Quran data) retain their original licenses.
