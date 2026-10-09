# NavAssist — Navigation Assistant App for Visually Impaired Pedestrians

IT3060 Human Computer Interaction — Milestone 03
Group WD_04

## Tech Stack

- Flutter (Dart)
- Firebase (Firestore + Authentication)
- Packages: flutter_tts, speech_to_text, vibration, go_router, provider

## Setup

1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. Clone this repo
3. Run `flutter pub get`
4. Add the `google-services.json` file (shared with the team separately) to `android/app/`

## Firebase

This project uses a shared Firebase project called `navassist-app`. The config file `google-services.json` is not included in this repo (it's gitignored for security) — it was shared directly with group members. If you need access to the Firebase console itself, ask to be added as a project member.

## Run

flutter run

## Build APK

flutter build apk --release

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Download the APK

Download the NavAssist Android application from the [Releases](../../releases) page.

**Latest release:** v1.0

Download `app-release.apk` from the release assets and install it on a compatible Android device. You may need to allow installation from the file manager used to open the APK.
