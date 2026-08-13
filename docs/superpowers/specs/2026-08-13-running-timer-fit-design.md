# Running Timer Fit Design

## Goal

Keep the `HH:MM:SS` chronometer fully inside the circular progress indicator on supported mobile widths without changing the circle or surrounding layout.

## Design

The timer remains centered and uses the existing IBM Plex Mono timer token. Its horizontal space is constrained to the circle's inner diameter with tokenized padding. A `FittedBox` using `BoxFit.scaleDown` preserves the configured timer size when it fits and scales the text down only on narrower screens.

The status label and planned-duration copy retain their current positions. The circle size, stroke, colours, and progress behaviour do not change.

## Verification

A widget test will assert that the timer's rendered bounds remain within the circular timer container. Existing running-state tests and the full project verification suite must continue to pass. The updated screen will also be checked on the Android emulator.
