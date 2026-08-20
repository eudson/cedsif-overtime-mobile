.PHONY: setup get build-runner build-runner-watch format analyze test policy-check ci-check run-local run-dev run-prod build-android build-ios icons doctor

setup:
	flutter pub get
	lefthook install

get:
	flutter pub get

build-runner:
	flutter pub run build_runner build --force-jit

build-runner-watch:
	flutter pub run build_runner watch --force-jit

format:
	dart format --output=none --set-exit-if-changed lib test

analyze:
	flutter analyze

test:
	flutter test

policy-check:
	tool/policy_check.sh

ci-check: policy-check format analyze test

run-local:
	@test -f .env.local || (echo "Missing .env.local; copy .env.example and set the local API URL" && exit 1)
	flutter run --dart-define-from-file=.env.local

run-dev:
	flutter run --dart-define-from-file=.env.dev

run-prod:
	flutter run --release --dart-define-from-file=.env.prod

build-android:
	flutter build appbundle --release --dart-define-from-file=.env.prod

build-ios:
	flutter build ios --release --no-codesign --dart-define-from-file=.env.prod

icons:
	flutter pub run flutter_launcher_icons

doctor:
	flutter doctor -v
