#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "policy check failed: $1" >&2
  exit 1
}

require_no_matches() {
  local message=$1
  shift
  if "$@" >/dev/null; then
    fail "$message"
  fi
}

test -s AGENTS.md || fail "AGENTS.md must contain the canonical repository guidance"
grep -Fq '[`AGENTS.md`](./AGENTS.md)' CLAUDE.md ||
  fail "CLAUDE.md must point to the canonical AGENTS.md"
grep -Fq '[`../AGENTS.md`](../AGENTS.md)' CLAUDE.md ||
  fail "CLAUDE.md must point to the workspace AGENTS.md"

git check-ignore -q docs/superpowers/policy-probe.md ||
  fail "docs/superpowers/ must be ignored"

if git ls-files -- docs/superpowers/ | grep -q .; then
  fail "docs/superpowers/ must not contain tracked files"
fi

if git ls-files | grep -Eq '\.(g|freezed)\.dart$'; then
  fail "generated .g.dart and .freezed.dart files must not be tracked"
fi

if [ -d lib/features ]; then
  require_no_matches \
    "feature domain code must not import Flutter" \
    rg -q --glob '*/domain/*.dart' --glob '*/domain/**/*.dart' \
    "^[[:space:]]*import[[:space:]]+['\"](package:flutter|dart:ui)" lib/features
fi

require_no_matches \
  "production code must use AppLogger instead of print" \
  rg -q --glob '*.dart' --glob '!*.g.dart' --glob '!*.freezed.dart' \
  '\bprint[[:space:]]*\(' lib

require_no_matches \
  "StateNotifier is prohibited; use Notifier" \
  rg -q --glob '*.dart' --glob '!*.g.dart' --glob '!*.freezed.dart' \
  '\bStateNotifier\b' lib

require_no_matches \
  "dartz is prohibited; use fpdart" \
  rg -q --glob '*.dart' --glob '!*.g.dart' --glob '!*.freezed.dart' \
  "package:dartz/" lib

require_no_matches \
  "relative Dart imports are prohibited" \
  rg --pcre2 -q --glob '*.dart' --glob '!*.g.dart' --glob '!*.freezed.dart' \
  "^[[:space:]]*import[[:space:]]+['\"](?!dart:|package:)" lib

require_no_matches \
  "Firebase and Sentry integrations are not part of this project" \
  rg -q \
  'firebase_core|firebase_analytics|sentry_flutter|FirebaseAnalytics|Firebase\.initializeApp|\bSentry\b|FIREBASE_|SENTRY_DSN|ENABLE_ANALYTICS' \
  pubspec.yaml .env.example .env.dev .env.prod AGENTS.md CLAUDE.md README.md \
  lib test android ios

if git log --format=%B | grep -Eqi '^Co-authored-by:'; then
  fail "Co-authored-by trailers are prohibited"
fi

echo "policy check passed"
