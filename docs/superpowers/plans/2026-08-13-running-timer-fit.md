# Running Timer Fit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the full `HH:MM:SS` chronometer inside the circular progress indicator on mobile screens.

**Architecture:** Preserve the existing running screen and typography token. Add a token for the timer's horizontal inset, constrain the `FittedBox` to the circle's inner width, and let `BoxFit.scaleDown` shrink only when needed.

**Tech Stack:** Flutter, widget tests, design tokens.

---

### Task 1: Constrain the running chronometer

**Files:**
- Modify: `test/features/home/presentation/portal_home_page_test.dart`
- Modify: `lib/theme/app_spacing.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`

- [ ] **Step 1: Write the failing bounds test**

Add keys for the timer circle and use the existing timer key. Assert that the rendered timer rectangle is horizontally inside the circle rectangle:

```dart
final circle = tester.getRect(
  find.byKey(const ValueKey('home-running-timer-circle')),
);
final timer = tester.getRect(
  find.byKey(const ValueKey('home-running-timer')),
);
expect(timer.left, greaterThan(circle.left));
expect(timer.right, lessThan(circle.right));
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
flutter test test/features/home/presentation/portal_home_page_test.dart --plain-name 'running timer fits inside its progress circle'
```

Expected: FAIL because the current timer extends beyond the circle or the circle key is absent.

- [ ] **Step 3: Add the tokenized inner inset and constrained scaler**

Add `runningTimerHorizontalInset = 24` to `AppSpacing`. Key the timer circle, then wrap the existing `FittedBox` in horizontal padding and a full-width `SizedBox`:

```dart
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.runningTimerHorizontalInset,
  ),
  child: SizedBox(
    width: double.infinity,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        _formatDuration(elapsed),
        key: const ValueKey('home-running-timer'),
        style: AppTypography.timerLarge,
      ),
    ),
  ),
)
```

- [ ] **Step 4: Run focused and complete verification**

Run:

```bash
flutter test test/features/home/presentation/portal_home_page_test.dart
make ci-check
git diff --check
```

Expected: all Home tests and the complete suite pass; analyzer reports no issues.

- [ ] **Step 5: Commit and deploy to emulator**

```bash
git add lib/theme/app_spacing.dart lib/features/home/presentation/pages/home_page.dart test/features/home/presentation/portal_home_page_test.dart
git commit -m "fix: fit chronometer inside progress circle"
flutter build apk --debug --dart-define-from-file=<existing-dev-env-file>
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Expected: debug APK builds, installs, and the running timer is visually contained by the circle.
