# Portal do FAE design system

The Portal do FAE interface is mobile-first, offline-friendly, and driven by
the public APIs in `lib/theme/` and `lib/widgets/`. Import the barrel files when
several tokens or components are needed:

```dart
import 'package:cedsif_overtime_mobile/theme/theme.dart';
import 'package:cedsif_overtime_mobile/widgets/widgets.dart';
```

## Tokens

### Colour

`AppColors` is the only source of colour values:

- `primary`, `secondary`, and `onPrimary` for branded actions;
- `success`, `successBackground`, `successSoft`, and `successDark`;
- `warning` and `warningBackground`;
- `danger` and `dangerBackground`;
- `background`, `surface`, `surfaceAlternative`, `canvas`, and `border`;
- `textPrimary`, `textStrong`, `textSecondary`, and `textMuted`;
- `disabled`, `offline`, and `offlineBackground`.

Use `Theme.of(context).colorScheme` inside general Material widgets and use
`AppColors` when a semantic Portal state is required.

### Typography

`AppTypography` supplies semantic styles:

- Poppins: `screenTitleLarge`, `screenTitle`, `sectionTitle`, `label`,
  `labelStrong`, `input`, `button`, and `small`;
- IBM Plex Sans: `body` and `bodyStrong`;
- IBM Plex Mono: `timerLarge` and `numericTotal`.

The fonts are bundled in `assets/fonts/`, so rendering never depends on a
runtime font download. Body text starts at 13 px or larger.

### Spacing and shape

`AppSpacing` owns layout dimensions. Use `space4` through `space80` for gaps
and padding, `radiusInput`, `radiusChip`, `radiusCard`, or `radiusPill` for
shape, and `touchTarget`/`buttonHeight` for interactive controls.

Do not add a one-off numeric dimension to a screen. Add a clearly named token
when the dimension represents a reusable design decision.

### Theme

`AppTheme.light` is the production design. `AppTheme.lightFor` and
`AppTheme.darkFor` preserve tenant-brand overrides used by the bootstrap.

```dart
MaterialApp(
  theme: AppTheme.light,
  home: const LoginScreen(),
);
```

## Components

### AppButton

Use `primary` for the main action, `secondary` for a non-destructive
alternative, and `destructive` for an irreversible action. A null callback
creates the disabled state. `isLoading` prevents repeat submission and replaces
the content with an accessible progress indicator.

```dart
AppButton(
  label: 'auth.enter'.tr(),
  leadingIcon: Icons.send_rounded,
  isLoading: state.isSubmitting,
  onPressed: state.canSubmit ? submit : null,
);
```

### AppTextField

`AppTextField` renders a persistent label, optional required marker, tokenized
input decoration, and Form validation/error output.

```dart
AppTextField(
  label: 'auth.nuit'.tr(),
  isRequired: true,
  keyboardType: TextInputType.number,
  validator: validateNuit,
);
```

### InfoCard

Use `InfoCard` for a short label/value pair with optional leading and trailing
icons. Supply `valueStyle: AppTypography.numericTotal` for numeric totals.

### StatusChip

`StatusChip` supports `emCurso`, `aprovada`, `pendente`, `bloqueado`, and
`offline`. Colour, icon, and localized copy are selected from the status enum;
screens must not reproduce that mapping.

### SemanticBanner

`SemanticBanner` supports `ok`, `warning`, and `danger`. Pass already-localized
copy through `message`. The banner announces the message as a live semantic
region.

### AppScaffold

`AppScaffold` supplies the shared safe area, Portal do FAE top bar, and
contextual navigation. Enable only what the screen needs:

```dart
AppScaffold(
  showTopBar: true,
  showBottomNavigation: true,
  currentIndex: 0,
  onDestinationSelected: handleDestination,
  body: const HomeContent(),
);
```

Bottom destinations are **Início**, **Histórico**, and **Perfil**. This slice
renders the menu consistently; History and Profile behavior belongs to later
feature slices.

## Localization and accessibility

All user-facing copy must be an `easy_localization` key. Portuguese is the
default and fallback locale. Do not embed display copy directly in production
widgets.

Maintain 56 px touch targets, preserve meaningful icon semantics, keep body
copy at least 13 px, and test error/loading/disabled states. White on primary
green passes WCAG AA contrast.

## Recommended next screens and components

1. Secure authentication state and session handling.
2. Facial validation plus camera and GPS permission guidance.
3. Active time-counting screen with chronometer and geofence changes.
4. Completion summary and offline submission queue.
5. History filters, list items, and record detail.
6. Profile and session management.
7. Startup connectivity, server-error, and offline-continuation screens.
