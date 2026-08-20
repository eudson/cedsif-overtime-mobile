# Horas Extras

Horas Extras is the production Flutter mobile foundation for CEDSIF overtime workflows. This bootstrap establishes platform, architecture, storage, networking, localization, observability, and delivery conventions. It intentionally contains no overtime business rules yet.

## Supported platforms

- Android
- iOS 15 or newer

Other Flutter platform scaffolding is not a supported delivery target for this application.

## Prerequisites

- Flutter stable with Dart 3.8 or newer
- Android Studio and an Android SDK for Android development
- Xcode with an iOS platform SDK, CocoaPods 1.16.2 or newer, and macOS for iOS development
- Lefthook for repository Git hooks
- A connected device or configured emulator/simulator

Check the local toolchain with:

```sh
make doctor
```

## First-time setup

Clone the repository, open its root, then run:

```sh
cp .env.example .env.dev
cp .env.example .env.prod
make setup
make build-runner
make ci-check
```

`make setup` installs Flutter packages and repository hooks. Use `make get` when only dependency resolution is needed.

Generated `*.g.dart` and `*.freezed.dart` files are deliberately ignored. Regenerate them after changing Freezed, JSON-serializable, or Riverpod annotations:

```sh
make build-runner
```

CI regenerates code before analysis and tests; generated Dart files must not be committed.

## Run and build

Environment files are required. Use the Make targets as the supported entry points:

```sh
make run-dev
make run-local
make run-prod
make build-android
make build-ios
```

- `run-dev` launches with `.env.dev`.
- `run-local` launches with the ignored `.env.local` developer override.
- `run-prod` launches a release build with `.env.prod`.
- `build-android` creates a release Android App Bundle using `.env.prod`.
- `build-ios` creates a release iOS build without code signing using `.env.prod`; signing remains a release-pipeline responsibility.

For an Android emulator calling an API on the development machine, copy
`.env.example` to the ignored `.env.local` file and set
`API_BASE_URL=http://10.0.2.2:8080`. Android
cleartext traffic is enabled only in the debug manifest; release builds retain
the platform's secure networking defaults. Use the development machine's LAN
address instead when testing on a physical device.

List the emulators and physical devices available to Flutter, then launch the
app on the selected target:

```sh
flutter devices
flutter run -d emulator-5554 --dart-define-from-file=.env.local
```

`emulator-5554` is an example device ID. Replace it with the ID of any other
running emulator or physical device connected to the development machine with
developer mode and USB debugging enabled. When using a physical device, ensure
that `.env.local` uses the development machine's reachable LAN address rather
than the emulator-only `10.0.2.2` alias.

Additional workflow targets:

```sh
make get
make build-runner
make ci-check
make icons
make doctor
```

`make ci-check` is the required local quality gate: repository policy,
formatting, static analysis, and tests. `make icons` regenerates Android and iOS
launcher icons from `assets/launcher_icon.png`.

## Build-time environment

Configuration is read through `EnvironmentConfig` from `--dart-define-from-file`. Copy `.env.example` and provide values appropriate to the target environment.

| Key | Meaning |
| --- | --- |
| `API_BASE_URL` | Base URL for first-party API requests. Authentication and queued replay are restricted to this origin. |
| `API_TIMEOUT` | Network timeout in milliseconds. Invalid or non-positive values use the application default. |
| `ENV` | Runtime profile: `development`, `staging`, or `production`. |

Values passed as Dart defines are embedded in the compiled application and can be recovered from it. Never place passwords, private keys, service-account credentials, access tokens, or other secrets in `.env.dev`, `.env.prod`, the repository, or Dart defines. Runtime credentials belong in secure storage and must come from an approved backend flow.

### Temporary facial-verification simulation

Until the SCVD integration is available, facial capture can be exercised only
with `ENV=development`. On the facial-verification screen, **Continue with
simulation** captures a still image and returns a temporary reference prefixed
with `SIMULATED-`, allowing the development flow to continue. The image remains
on the device only for the duration of the simulation and is deleted
immediately afterwards; this temporary flow neither uploads nor persists it.

Set `ENV=staging` or `ENV=production` to disable the simulation. Those profiles
do not initialize the camera and fail closed, blocking continuation until real
backend-to-SCVD verification is implemented. Never enable the simulated
verifier in staging or production. Developers can enable or disable the flow by
changing `ENV` in the selected `.env.dev` or ignored `.env.local` file and
restarting the app.

### Location capture and geofence authority

The application requests foreground location only when an overtime start needs
a fresh coordinate. It does not request background or always-on access and does
not continuously track the user. The mobile app sends latitude and longitude to
the API; the backend is authoritative for the employee's work-unit perimeter
and returns `locationVerified`. The current backend defaults (200-metre radius;
record and flag an outside start) remain marked for confirmation by CEDSIF and
must not be duplicated as mobile constants.

## Architecture

The application uses feature-first Clean Architecture:

```text
lib/
├── core/                         shared platform infrastructure
│   ├── config/                   environment and routing
│   ├── constants/                routes, API paths, dimensions, timings
│   ├── error/                    exceptions, failures, mapping
│   ├── network/                  Dio, authentication, refresh, cache
│   ├── storage/ and database/    preferences, secrets, Hive
│   ├── sync/                     transport-neutral pending work
│   └── theme/, branding/, utils/, widgets/
├── features/<feature>/
│   ├── domain/                   entities, repository contracts, use cases
│   ├── data/                     models, data sources, repository implementations
│   └── presentation/             pages, Riverpod Notifiers, widgets
├── bootstrap.dart                guarded runtime initialization
├── app.dart                      application shell
└── main.dart                     bootstrap entry point
```

Layer rules:

- Dependencies flow from presentation to data to domain, never in reverse.
- Domain code is pure Dart and must not import Flutter or platform APIs.
- Domain entities use Equatable; repository contracts return `Either<Failure, T>` from fpdart.
- Data models use Freezed/JSON serialization and convert explicitly to and from entities.
- Repository implementations catch exceptions and return typed failures; presentation never receives raw exceptions.
- Riverpod dependency injection follows data source → repository → use case → `NotifierProvider`.
- Routes, API paths, colors, dimensions, and user-facing strings come from their central constants/localization owners.

## Runtime services

WorkManager is a non-critical bootstrap service. Initialization failures are isolated, safely logged through `AppLogger`, and do not prevent the application shell from starting. Fatal framework and zoned errors are redacted before local logging.

WorkManager processes only generic, network-constrained queued requests. Networking injects secure credentials only for the configured first-party API origin, refreshes an expired session once, isolates cached GET responses by session scope and TTL, and never stores authorization values in cache keys or queued headers.

### Authentication and offline sessions

Login sends the FAE's NUIT and password to `POST /auth/login` through the auth
data source, repository, and use case. Access and refresh tokens are stored in
platform secure storage; the password and password-derived values are never
persisted.

After one successful online login, the application can reopen without network
access only while the cached access JWT is unexpired. The backend currently
issues access tokens with a 3,600-second default lifetime. An expired or
malformed access token is cleared together with its refresh token, and the FAE
must go online to authenticate again. This client-side route gate supports
offline usability; the backend remains the authority for every protected API
request.

The hamburger menu exposes a confirmation-protected logout action. When online,
the app revokes the refresh session through `POST /auth/logout` before clearing
local credentials. Offline logout still clears local credentials immediately;
unsynchronized overtime data is retained, while remote revocation relies on the
refresh session's server-side expiry.

**CEDSIF discussion item:** the current delivery assumes one FAE per app
installation. Before supporting shared devices, queued writes must be bound to
the originating FAE so a later login cannot replay another FAE's pending work.

**CEDSIF discussion item — not implemented:** CEDSIF may consider allowing a
separate, longer offline-login window using a salted password-derived verifier
stored in hardware-backed secure storage. That option requires explicit
agreement on its offline TTL, failed-attempt lockout, credential-revocation
behavior, device-compromise risk, and audit requirements before implementation.

## Bootstrap scope

The current home feature is a neutral architecture proof that renders localized placeholder content. No employee, timesheet, overtime-rate, approval, payroll, attendance, or calculation policy has been assumed.

This repository also excludes unrelated product domains such as payments, point-of-sale, checkout, inventory, ecommerce, banking, lending, and accounting. Business behavior will be introduced only from approved CEDSIF requirements.

## Pending release setup

The generic application bootstrap is complete. The following external release and product inputs are still required:

- [ ] Install or repair the iOS 26.2 platform component in the active Xcode installation, then verify `make build-ios`.
- [ ] Configure Android production signing through the approved secure release pipeline; local release builds currently use debug signing.
- [ ] Replace the placeholder `API_BASE_URL` in the target environment files after the backend endpoint is approved.
- [ ] Implement overtime workflows only after CEDSIF supplies and approves the business requirements.

## Repository policy

Run the policy guard directly when changing project conventions:

```sh
tool/policy_check.sh
```

The guard verifies the canonical instruction file and its compatibility pointer,
ignored local planning artifacts, generated-file policy, domain purity, import
conventions, prohibited APIs/packages, and commit attribution rules.
