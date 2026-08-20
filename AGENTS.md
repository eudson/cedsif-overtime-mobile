# cedsif-overtime-mobile — Agent Guide

> Canonical instruction file for **this repository**. `CLAUDE.md` here points to
> this file (they were byte-identical before; now both defer here). For
> cross-repo/workspace rules see the workspace `AGENTS.md` one level up.

You are working as a **senior Flutter / Dart engineer** on the CEDSIF Horas
Extraordinárias mobile app — offline-first, for FAEs on Android and iOS.

---

## 1. Stack (as built)

- **Dart SDK `>=3.8.0 <4.0.0`**, Flutter stable channel. App `1.0.0+1`.
- **flutter_riverpod ^3** (+ `riverpod_annotation`) — state & DI.
- **go_router ^17** — routing.
- **dio ^5** — HTTP: interceptors, single-flight token refresh on 401,
  session-scoped GET cache, queued replay. `pretty_dio_logger` (redacted).
- **freezed / json_annotation** — immutable models & states (code-gen).
- **fpdart ^1** — `Either<Failure, T>` at repository boundaries.
- **hive / hive_flutter** — local cache, pending-request queue, local state.
- **flutter_secure_storage** — access/refresh tokens. **shared_preferences** —
  primitives.
- **easy_localization** — pt (default/fallback) / en / es.
- **workmanager** — periodic (15-min) background queue processing.
- **connectivity_plus** — online/offline monitoring.

### Being added this phase (real capabilities)
- **`local_auth`** + **`camera`** — real facial capture, validated via backend →
  SCVD. Replaces `FacialValidationStubPage`.
- **`geolocator`** + **`permission_handler`** — real geolocation + per-UGB
  geofence enforcement; declare Android/iOS permissions (see §6).

Add these to `pubspec.yaml`, wire real flows, and add the platform permissions —
don't leave them as stubs. See workspace `RECONCILIATION_PLAN.md` for order.

---

## 2. Architecture

**Feature-first + Clean Architecture layering.** Match what's there:

```
lib/
├── app.dart · bootstrap.dart · main.dart
├── core/        branding, config, constants, database, error, network,
│                storage, sync, theme, utils, widgets
└── features/<feature>/
    ├── data/          data sources, DTOs, repository implementations
    ├── domain/        entities, repository interfaces, use cases
    └── presentation/  screens, widgets, Riverpod notifiers/providers
```

- **Domain purity** is enforced by `tool/policy_check.sh` (domain layer must not
  import data/presentation or framework specifics). Respect it.
- Repositories return **`Either<Failure, T>`** (fpdart). No throwing across the
  repository boundary for expected failures.
- State via **Riverpod notifiers**; providers overridden in `bootstrap.dart`.
  `providers.dart` intentionally throws `UnimplementedError` for bootstrap-only
  resources used without overrides — that's a guard, not a bug.
- **Never hand-edit** `*.g.dart` / `*.freezed.dart`. Edit sources, run codegen
  (`make gen` / build_runner).

---

## 3. Current state — demo vs real (important)

Much of the overtime flow is a **local demo**, not backend-wired. Know the
difference before you build:

- **Auth:** login UI validates NUIT/password locally then just navigates — **no
  API call**. Facial validation is an explicit **stub**. Router redirect
  (`appRedirect`) is a **no-op** — no session gate.
- **Overtime:** start/pause/resume/timer/submit work **locally**; submit writes
  only to local Hive history under `demo_overtime_*` keys with **seeded July 2026
  data**. Nothing is enqueued to `pending_requests`; `SyncEngine` watches
  connectivity but doesn't process the queue.
- **API client is real** (Dio with refresh + cache + queue) but only two endpoint
  constants exist (`/health`, `/auth/refresh`) and no login/overtime/history data
  source calls the backend.
- **Home** has full Clean-Architecture scaffolding but its data source returns a
  placeholder; the router uses the overtime route instead.

**Your job across tasks is to replace demo behaviour with real,
backend-synchronized flows** — real login, real submission enqueued for
offline replay, real history from the API — against the endpoints the backend is
building (workspace `AGENTS.md` §5). Don't extend the demo; wire the real thing.

---

## 4. Offline-first — how it must work

The infrastructure exists; use it correctly:

- **Writes** (start/end/submit overtime): go through the API client so that,
  when offline, they land in the **`pending_requests`** Hive queue with an
  **idempotency key**, and replay via WorkManager when connectivity returns.
  The overtime feature must actually enqueue — today it does not.
- **Reads**: session-scoped GET cache (15-min TTL) already serves offline GETs.
- Keep feature state out of the generic HTTP cache box. The demo stores overtime
  in the shared `cache` box under `demo_overtime_*`; real overtime persistence
  needs its **own box / clear boundary** — see reconciliation plan.
- The backend honours the same idempotency key (`DAILY_SUBMISSION.idempotency_key`),
  so a replayed submission never double-counts. Keep the client key stable per
  (FAE, action, day).

---

## 5. Auth flow — target

- **Login:** `POST /auth/login` with **NUIT + password** → access + refresh
  tokens stored in secure storage. Replace the fake delay-then-navigate.
- **Refresh:** already wired (`POST /auth/refresh`, single-flight on 401).
- **Session gate:** implement `appRedirect` so unauthenticated users can't reach
  protected routes (currently a no-op).
- **Facial validation:** real `camera` capture → send to backend → SCVD result
  gates entry. Replace `FacialValidationStubPage`.

---

## 6. Platform permissions (add with the new capabilities)

- **Android** (`android/app/src/main/AndroidManifest.xml`): add
  `CAMERA`, `ACCESS_FINE_LOCATION` (+ coarse), and any needed
  foreground/background location per the geofence design. `INTERNET` already
  present.
- **iOS** (`ios/Runner/Info.plist`): add `NSCameraUsageDescription`,
  `NSLocationWhenInUseUsageDescription` (and location-always if the geofence
  needs it), and Face ID usage (`NSFaceIDUsageDescription`) for `local_auth`.
- Localize all permission rationale strings.
- **Signing:** release currently uses the **debug** signing config — production
  signing is an open release-readiness item (reconciliation plan), don't ship
  without it.

---

## 7. Quality gates (must pass before "done")

```bash
make ci-check          # format + analyze + test — the definition of done
make gen               # build_runner code generation (freezed/json/riverpod)
tool/policy_check.sh   # instruction-file identity, domain purity, imports,
                       # prohibited APIs/packages, generated-file policy
```

- **lefthook** runs format/analyze/test pre-commit.
- **analysis_options.yaml** is strict: no `print`, no relative imports, const
  constructors, final locals, single quotes, trailing commas, async-context
  safety. Don't relax it to pass.
- **TDD:** the repo has ~59 test files / ~169 cases with `flutter_test` +
  **Mocktail**. New features need domain/data/provider/widget tests matching the
  `overtime` feature's coverage. Add **integration_test** for end-to-end flows
  (none exists yet).
- Never hard-code user-facing strings — add keys to **all** locale files
  (en/es are currently incomplete; new keys must not make that worse).

---

## 8. Conventions

- English Dart identifiers. **New enums/state in English** — the repo has legacy
  Portuguese identifiers (`emCurso`, `aprovada`, `pendente`, `bloqueado`) and
  Portuguese route strings (`/validacao-facial`, `/historico`); the
  reconciliation plan owns aligning them. Don't add new Portuguese identifiers.
- Design tokens & reusable widgets: follow **`THEME.md`** (Portal do FAE tokens,
  accessibility). Don't introduce ad-hoc colors/spacing.
- Consolidate the duplicated shared UI (`core/theme` + `core/widgets` vs
  top-level `theme/` + `widgets/`) only as the reconciliation plan directs —
  not opportunistically mid-feature.
- Supported delivery targets are **Android + iOS** (per README) despite
  linux/macos/web/windows scaffolding being present.

---

## 9. Fast repo map

- Bootstrap/DI: `bootstrap.dart`, `core/config` (`EnvironmentConfig` reads
  `API_BASE_URL`/`API_TIMEOUT`/`ENV` from `--dart-define`), `.env.{example,dev,prod}`.
- Network: `core/network` (`NetworkClient`, interceptors, endpoint constants).
- Offline: `core/database` (`AppDatabase`, Hive boxes `cache`,
  `pending_requests`), `core/sync` (`SyncEngine`), `core/storage`.
- Overtime feature (most complete): `features/overtime/{data,domain,presentation}`.
- Reference for full-layer wiring: `features/home` (scaffolded, placeholder data).
- Theme: `THEME.md`, `core/theme`, `theme/`.
- CI: `.github/workflows/ci.yml` (PRs: pub get → codegen → `make ci-check`).
- Policy: `tool/policy_check.sh` (note: wire it into `ci-check`/CI per
  reconciliation plan — currently not invoked there).
