# Awake style guide

One control, nothing loud. White, light grey, black.

## Rules

- The panel is a single glass capsule floating under the menu bar, with no window, popover or background behind it.
- One shape, one edge. The glass rim is the only border; nothing gets a hairline or frame.
- No text in the panel. Tooltips and accessibility labels carry the words.
- No color. No accent blue, no focus rings, always the light appearance.
- Anything that isn't the toggle lives in the right-click menu, as a standard `NSMenu`.

## Palette

| Token | Value | Use |
|---|---|---|
| track | white 86% at 80%, as a glass tint | The light grey glass capsule. Grey enough that the white pill stands out, even over white windows. |
| pill | pure white; shadow black 10%, radius 1.5, y 1; no border | The selected choice, raised |
| ink | black 86% | Selected icon |
| ink quiet | black 32% | Unselected icon |
| accent | #1C1C1C | App-wide accent color, so no system control turns blue |

## Layout

- The capsule sits 2pt below the menu-bar icon, centered on it and kept on screen.
- Track padding 3pt, 2pt between segments.
- Segments 44 × 30pt, capsule-shaped. Icons are SF Symbols at 14pt, medium weight.

## Motion

- The capsule fades in (0.15s) and out (0.12s). A click anywhere else or Escape closes it.
- The white pill slides between segments (`matchedGeometryEffect`, `.smooth(duration: 0.28)`).
- Nothing else animates.

## Icons

| Where | Icon |
|---|---|
| Menu bar | `cup.and.saucer` (sleeping normally), `cup.and.saucer.fill` (awake). Template images, so macOS tints them. |
| Panel | `moon.zzz` = let the Mac sleep, `cup.and.saucer.fill` = keep it awake |
| App icon | A white squircle with a black cup, drawn by `tools/make-icon.swift`. It's hand-drawn because Apple's license doesn't allow SF Symbols in app icons. |

## APIs

| What | API |
|---|---|
| Glass | SwiftUI `glassEffect(_:in:)` with `Glass.regular.tint(_:)` |
| Panel | Borderless, transparent `NSPanel` (`.nonactivatingPanel`, level `.statusBar`) hosting the SwiftUI view in an `NSHostingView`, appearance forced to `.aqua`. `NSEvent` monitors close it on an outside click or Escape. |
| Menu bar | `NSStatusItem` with a template `NSImage(systemSymbolName:)` |
| Keeping awake | `IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep)` / `IOPMAssertionRelease`, the same as `caffeinate -d` |
| Open at login | `SMAppService.mainApp.register()` / `unregister()` |
| State | Observation (`@Observable`); `withObservationTracking` keeps the menu-bar icon in sync |

Apple references: Human Interface Guidelines, [Materials](https://developer.apple.com/design/human-interface-guidelines/materials) (Liquid Glass) and [The menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar).
