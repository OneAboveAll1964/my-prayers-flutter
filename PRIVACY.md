# Privacy Policy — Sakina

_Last updated: 2026-05-07_

Sakina is a personal Islamic companion app for Android and iOS. It is built and maintained by an individual developer ([OneAboveAll1964](https://github.com/OneAboveAll1964)) and operates entirely on your device.

## Short version

**Sakina does not collect, transmit, sell, or share any personal data.** Everything you see in the app — your location for qibla and prayer times, the dhikr counts, the surah you last read, your widget preferences — lives on your phone and stays on your phone.

There are no analytics, no advertising SDKs, no crash reporting services, and no third-party trackers in the app.

## Permissions explained

The app asks for the following permissions only because the corresponding features can't work without them. Each is requested at the point of first use, and you can revoke any of them in your phone's system settings without uninstalling the app.

| Permission | Why it's used | Where the data goes |
|---|---|---|
| **Location** (`ACCESS_FINE_LOCATION` / `NSLocationWhenInUseUsageDescription`) | One-time read to detect your nearest city for prayer-time calculation and to point the qibla compass toward Makkah. | Used in-process to look up the matching city in the bundled SQLite database, then discarded. Never sent to any server. |
| **Notifications** (`POST_NOTIFICATIONS` on Android 13+ / iOS notification authorization) | To show the prayer-time alerts you enabled in Settings → Notifications. | Local-only `flutter_local_notifications` schedule. The notification payload (prayer name + time) is composed on-device. |
| **Exact alarms** (`USE_EXACT_ALARM` on Android 12+) | So adhan notifications fire at the precise prayer time set by your chosen calculation method, not minutes later. | Used to register `AlarmManager.setAlarmClock()` entries with the OS. No third party involved. |
| **Boot received** (`RECEIVE_BOOT_COMPLETED` on Android) | So the prayer schedule is re-armed after you reboot the phone — without it you'd lose notifications until you next opened the app. | The app re-runs its local scheduler. Nothing leaves the device. |

## Data we don't collect

- Personal identifiers (name, email, phone number, account ID, IDFA, Android Advertising ID, etc.)
- Usage analytics or feature telemetry
- Crash reports or diagnostic logs
- IP address or any network-derived signal
- Contacts, photos, microphone, camera, calendar, or any other system resource

## Data stored locally on your device

The following is saved in the app's private storage area (sandboxed by the operating system, not readable by other apps):

- Your selected location (city name + lat/long)
- Your settings (theme, language, calculation method, notification toggles, font preferences, time format)
- Bookmarks, last-read surah, and dhikr counters
- Home-screen widget configuration

This data is removed automatically when you uninstall the app.

## Bundled content

The app ships with the following content embedded at build time. None of it is fetched at runtime:

- **`muslim_db_v3.0.0.db`** — open SQLite database of cities, prayer chapters (Hisnul Muslim), and qibla data
- **Quran text** — three editions (Uthmani, Sahih International, Muyassar, Asan Kurdish) bundled as JSON
- **Adhan audio** — Ahmed al-Imadi recording, distributed under a Public Domain Mark / CC0
- **Arabic fonts** — Uthmanic Hafs, Amiri Quran, KFGQPC Nastaleeq, Scheherazade New, Noto Naskh Arabic (each under its respective open license)

## Network usage

The app makes **no network requests** for its core functionality. The only outbound connection it can initiate is opening the `https://github.com/OneAboveAll1964` link in your default browser if you tap the "Made by OneAboveAll1964" credit in Settings — that handoff is performed by the system browser, not by the app.

## Children's privacy

The app contains no advertising, no in-app purchases, and no user-generated content. There is nothing in the app that targets, identifies, or collects information about children.

## Changes to this policy

This file in the repository is the authoritative version. If anything in the app's data handling materially changes in a future version, this policy will be updated and the change will be noted at the top.

## Contact

Questions about this policy: open an issue at <https://github.com/OneAboveAll1964/my-prayers-flutter/issues>.
