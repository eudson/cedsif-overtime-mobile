# Horas Extras

Production Flutter app: Clean Architecture · Riverpod 3 · GoRouter · Freezed · fpdart.
**Read this file fully before your first task.** It is the source of truth for how to work here.

## Stack
State/DI: flutter_riverpod 3.1 (`Notifier<T>`) · Nav: go_router 17 · HTTP: dio 5 (interceptor chain)
Models: freezed 3 + json_serializable (codegen) · Errors: `Either<Failure, T>` via fpdart (NOT dartz)
Storage: Hive (cache) + flutter_secure_storage (secrets) + shared_preferences · i18n: easy_localization (en, es)
Obs: sentry_flutter + firebase_analytics + AppLogger · Background: workmanager

## Absolute rules — never violate
1. Never hardcode colors → `AppColors` (`core/constants/app_colors.dart`)
2. Never hardcode API paths → `ApiEndpoints` (`core/constants/api_endpoints.dart`)
3. Never hardcode magic numbers → `AppConstants` (`core/constants/constants.dart`)
4. Never hardcode routes → `RouteConstants` (`core/constants/constants.dart`)
5. Never hardcode user-facing strings → `'key'.tr()` (easy_localization)
6. Never import Flutter in `domain/` — pure Dart only
7. Never use `print()` → `AppLogger` (`core/utils/logger.dart`)
8. Never use relative imports → always `package:cedsif_overtime_mobile/...`
9. Never edit generated files → `*.g.dart`, `*.freezed.dart`
10. Never use `StateNotifier` → use `Notifier<T>`
11. Never use `dartz` → this project uses `fpdart`
12. Never use `BuildContext` across async gaps without checking `mounted`
13. Never skip codegen → run `make build-runner` after `@freezed`/`@JsonSerializable`/`@riverpod` changes
14. Never version-control local planning artifacts under `docs/superpowers/`
15. Never add `Co-authored-by` trailers or otherwise attribute changes to an AI assistant

## Architecture — feature-first, 3 layers
lib/
├── core/          config · constants · error · network · storage · database · sync · theme · branding · utils · widgets
├── features/{name}/
│   ├── domain/      entities (Equatable) · repositories (abstract) · usecases (one op each)  ← pure Dart
│   ├── data/        datasources · models (freezed + toEntity/fromEntity) · repositories (impl, returns Either)
│   └── presentation/ pages (Consumer widgets) · providers (Notifier) · widgets
├── bootstrap.dart  app init (runZonedGuarded)
├── app.dart        MaterialApp.router
└── main.dart       void main() => bootstrap();
Dependency rule: presentation → data → domain. Never reverse.

## Patterns
Entity (domain): `class X extends Equatable { ...; List<Object?> get props => [...]; }`
Model (data): `@freezed` class with `fromJson`, `toEntity()`, `fromEntity()`.
Repo interface (domain): `Future<Either<Failure, T>> op(...)`.
Repo impl (data): wrap datasource call in try/catch → `Right(model.toEntity())` / `Left(XFailure(...))`.
Provider (presentation):
    class XNotifier extends Notifier<XState> {
      @override XState build() => const XState.initial();
      Future<void> load() async {
        state = state.copyWith(isLoading: true);
        final r = await ref.read(xUseCaseProvider).call();
        r.fold((f) => state = state.copyWith(isLoading:false, error:f.message),
               (d) => state = state.copyWith(isLoading:false, data:d));
      }
    }
    final xNotifierProvider = NotifierProvider<XNotifier, XState>(XNotifier.new);
`ref.watch()` in build, `ref.read()` in callbacks.
DI chain: Provider<DataSource> → Provider<Repository> → Provider<UseCase> → NotifierProvider.

## Environment
Values are build-time only (`--dart-define-from-file`), read via `EnvironmentConfig`. A plain
`flutter run` boots with empty config and looks broken — always use `make run-dev`/`make run-prod`.
Copy `.env.example` → `.env.dev`. Keys: API_BASE_URL, API_TIMEOUT, ENV, FIREBASE_*, SENTRY_DSN, ENABLE_ANALYTICS.

## Commands (always run ci-check before committing)
    make setup          # first-time setup
    make get            # deps
    make build-runner   # codegen (after annotated-code changes)
    make ci-check       # format + analyze + test  ← gate
    make run-dev        # run in dev

## Add a feature
1. `lib/features/{name}/{domain,data,presentation}/...`
2. domain: entity → repo interface → usecase
3. data: freezed model (`toEntity`) → datasource → repo impl (Either)
4. presentation: Notifier provider → page → widgets
5. route in `core/config/router.dart` + `RouteConstants`; strings in `assets/translations/{en,es}.json`
6. `make build-runner` → `make ci-check`

## Naming
Files snake_case with suffix: `*_page`, `*_provider`, `*_model`, `*_usecase`, `*_datasource`, `*_repository`.
Classes PascalCase · vars camelCase · private `_` prefix · tests mirror source path + `_test.dart`.

## Import order
dart: → package:flutter → third-party → package:cedsif_overtime_mobile/... (absolute)

## General engineering
- Small, single-responsibility widgets/functions; read a file fully before editing it.
- Fail loud in dev, degrade gracefully in prod: non-critical init failures log a warning and the app still boots.
- Redact tokens/PII before logging (`LogRedactor`). No secrets in code or logs.
- Prefer composition over inheritance; keep `domain/` free of framework/IO concerns for testability.
- Every change ends green on `make ci-check`; add/adjust tests for logic you touch.

