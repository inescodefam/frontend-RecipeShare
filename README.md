# RecipeShare Frontend Monorepo

RecipeShare is a Flutter monorepo with:
- a **mobile app** for end users (`iOS` / `Android`)
- a **web admin panel** for managing platform content
- a shared Dart package used by both apps

The project is designed to work with a REST backend (currently mixed mock + HTTP services depending on feature area).

## Who this README is for

- **Backend team:** understand expected API shape and how frontend integration is wired.
- **New contributors:** run mobile/admin quickly on local machines.

## Repository structure

- `recipeshare/apps/mobile` - mobile app entrypoint
- `recipeshare/apps/admin` - admin web app entrypoint
- `recipeshare/packages/shared` - shared models, services, theme, and widgets

## How backend integration works

- The frontend keeps service interfaces in `packages/shared/lib/services`.
- Some modules already use HTTP services (for example auth and admin catalog endpoints).
- Other areas may still use mock data/services while backend endpoints are being finalized.
- App startup wires dependencies from `main.dart` (mock vs API setup).

For backend contract context, also review:
- `recipeshare/packages/shared/lib/mock_data/`
- `recipeshare/packages/shared/lib/models/`

## Prerequisites

Install these tools first:

1. **Flutter SDK** (stable channel): [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
2. **Git**
3. **Chrome** (for Flutter web admin)
4. **Android Studio** (Android SDK + emulator) and/or **Xcode** (for iOS on macOS)

Then verify setup:

```bash
flutter doctor
flutter --version
```

## Clone and bootstrap

From repo root:

```bash
git clone <your-repo-url>
cd frontend-RecipeShare
```

Install dependencies for each package:

```bash
cd recipeshare/packages/shared
flutter pub get

cd ../../apps/mobile
flutter pub get

cd ../admin
flutter pub get
```

## Devices and emulators

List available devices:

```bash
flutter devices
```

List configured emulators:

```bash
flutter emulators
```

Launch an emulator:

```bash
flutter emulators --launch <emulator_id>
```

If no Android emulator is available, create one in Android Studio:
- `Tools` -> `Device Manager` -> `Create device`

## Run the apps

### Mobile app (Android/iOS)

```bash
cd recipeshare/apps/mobile
flutter run
```

Run on a specific device:

```bash
flutter run -d <device_id>
```

### Admin app (Web)

```bash
cd recipeshare/apps/admin
flutter run -d chrome
```

## Useful CLI commands

From each app/package directory:

```bash
flutter pub get
dart analyze
flutter test
```

Build artifacts:

```bash
# Mobile APK (debug)
cd recipeshare/apps/mobile
flutter build apk --debug

# Admin web build
cd ../admin
flutter build web
```

## API base URL and environments

Each app has `api_config.dart` for API endpoint selection.  
Set backend URL there (or through the mechanism already used in that file) when testing against real APIs.

## CI / SonarCloud notes

- CI workflow lives in `.github/workflows/build.yml`.
- Sonar configuration is in `sonar-project.properties`.
- Source scanning includes:
  - `recipeshare/apps/mobile/lib`
  - `recipeshare/apps/admin/lib`
  - `recipeshare/packages/shared/lib`

## Troubleshooting

- **`No pubspec.yaml file found`**  
  Run Flutter commands from the correct package folder (`apps/mobile`, `apps/admin`, or `packages/shared`), not always from repo root.

- **Device not detected**  
  Run `flutter doctor` and resolve platform-specific warnings.

- **Web run issues**  
  Ensure Chrome is installed and visible in `flutter devices`.

  ## Demo

  You can enjoy demo on the [link](https://drive.google.com/drive/folders/17KHBp4zdkk1iP9_0Uq4fz3T1tmEb9qJb?usp=sharing)
