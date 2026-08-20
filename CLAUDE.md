# CLAUDE.md — cedsif-overtime-mobile

**Canonical guidance for this repo is [`AGENTS.md`](./AGENTS.md).** Read it fully.
The workspace-level [`../AGENTS.md`](../AGENTS.md) governs cross-repo concerns.

Essentials (all detailed in `AGENTS.md`):

- Senior **Flutter / Dart**, offline-first. Feature-first Clean Architecture,
  **Riverpod**, **Dio**, **Hive**, **fpdart**, freezed/json codegen.
- Much of the overtime flow is a **local demo** (seeded data, no backend calls,
  submit not enqueued). **Your job is to wire the real backend flows**, not
  extend the demo.
- **Auth target:** `POST /auth/login` (**NUIT + password**) + `/auth/refresh`
  (already wired), real session gate (`appRedirect` is currently a no-op).
- **Add real capabilities this phase:** `local_auth` + `camera` (replace facial
  stub), `geolocator` + `permission_handler` (geofence) — plus Android/iOS
  permissions. See `../RECONCILIATION_PLAN.md`.

Definition of done: **`make ci-check` green** (format + analyze + test) and
`tool/policy_check.sh` passing. Run `make gen` after touching freezed/json/riverpod
sources; never hand-edit `*.g.dart`/`*.freezed.dart`. TDD first. Follow `THEME.md`
for UI. Never hard-code user-facing strings (add keys to all locales). New
identifiers/enums in English. Don't invent overtime business rules — if
unspecified, stop and ask.
