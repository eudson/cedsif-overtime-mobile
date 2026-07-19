# Horas Extras

Horas Extras is the production Flutter mobile foundation for CEDSIF overtime workflows. This bootstrap establishes platform, architecture, storage, networking, localization, observability, and delivery conventions. It intentionally contains no overtime business rules yet.

## Supported platforms

- Android
- iOS

Other Flutter platform scaffolding is not a supported delivery target for this application.

## Prerequisites

- Flutter stable with Dart 3.8 or newer
- Android Studio and an Android SDK for Android development
- Xcode, CocoaPods, and macOS for iOS development
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
make run-prod
make build-android
make build-ios
```

- `run-dev` launches with `.env.dev`.
- `run-prod` launches a release build with `.env.prod`.
- `build-android` creates a release Android App Bundle using `.env.prod`.
- `build-ios` creates a release iOS build without code signing using `.env.prod`; signing remains a release-pipeline responsibility.

Additional workflow targets:

```sh
make get
make build-runner
make ci-check
make icons
make doctor
```

`make ci-check` is the required local quality gate: formatting, static analysis, and tests. `make icons` regenerates Android and iOS launcher icons from `assets/launcher_icon.png`.

## Build-time environment

Configuration is read through `EnvironmentConfig` from `--dart-define-from-file`. Copy `.env.example` and provide values appropriate to the target environment.

| Key | Meaning |
| --- | --- |
| `API_BASE_URL` | Base URL for first-party API requests. Authentication and queued replay are restricted to this origin. |
| `API_TIMEOUT` | Network timeout in milliseconds. Invalid or non-positive values use the application default. |
| `ENV` | Runtime profile: `development`, `staging`, or `production`. |
| `SENTRY_DSN` | Sentry project DSN. Empty disables Sentry initialization. |
| `ENABLE_ANALYTICS` | Enables analytics only when set to `true` and initialization succeeds. |
| `FIREBASE_API_KEY` | Firebase API key for the selected project. |
| `FIREBASE_APP_ID` | Firebase application identifier. |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase messaging sender identifier. |
| `FIREBASE_PROJECT_ID` | Firebase project identifier. |
| `FIREBASE_STORAGE_BUCKET` | Firebase storage bucket identifier. |

Values passed as Dart defines are embedded in the compiled application and can be recovered from it. Never place passwords, private keys, service-account credentials, access tokens, or other secrets in `.env.dev`, `.env.prod`, the repository, or Dart defines. Runtime credentials belong in secure storage and must come from an approved backend flow.

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

Firebase, analytics, Sentry, and WorkManager are non-critical bootstrap services. Initialization failures are isolated, safely logged through `AppLogger`, and do not prevent the application shell from starting. Disabled or incomplete configuration degrades to no-op behavior where supported.

WorkManager processes only generic, network-constrained queued requests. Networking injects secure credentials only for the configured first-party API origin, refreshes an expired session once, isolates cached GET responses by session scope and TTL, and never stores authorization values in cache keys or queued headers.

## Bootstrap scope

The current home feature is a neutral architecture proof that renders localized placeholder content. No employee, timesheet, overtime-rate, approval, payroll, attendance, or calculation policy has been assumed.

This repository also excludes unrelated product domains such as payments, point-of-sale, checkout, inventory, ecommerce, banking, lending, and accounting. Business behavior will be introduced only from approved CEDSIF requirements.

## Repository policy

Run the policy guard directly when changing project conventions:

```sh
tool/policy_check.sh
```

The guard verifies instruction-file identity, ignored local planning artifacts, generated-file policy, domain purity, import conventions, prohibited APIs/packages, and commit attribution rules.
