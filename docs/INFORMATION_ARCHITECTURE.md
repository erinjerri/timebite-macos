# Information Architecture

## Summary

TimeBite macOS uses a workspace-oriented shell with two top-level spaces:

- `TimeBite`
- `Creating Your Reality`

The key design rule is that the app must switch spaces without changing apps or presenting a mobile-style tab bar.

## Navigation Model

### App Space

The app has one persisted top-level state:

- `AppSpace.timeBite`
- `AppSpace.creatingYourReality`

The selected space persists across launches using `@AppStorage`.

### Destination Model

Each space owns its own destination set:

#### TimeBite

- Now
- Actions
- Goals
- Plan
- Track
- Dashboard

#### Creating Your Reality

- Create
- Discover
- Journal
- Library
- Me

Only one space's destinations are visible at a time.

## Layout Principles

- Use `NavigationSplitView` for macOS-native workspace behavior.
- Keep the shell spacious but information dense.
- Use placeholder cards that establish section geometry without overcommitting to final content.
- Make resizing feel safe at approximately 1200 to 1600 px wide.
- Avoid a mobile-sized card grid stretched across the desktop.

## Shell Hierarchy

1. App entry point
2. Root shell
3. App space switcher
4. Space-specific primary navigation
5. Destination view

## Current Implementation Notes

The initial shell includes:

- persisted top-level space selection
- sidebar-based navigation
- single active destination per space
- a real `Now` shell with reserved layout regions
- placeholder surfaces for all remaining destinations

## Now View Regions

The `Now` page reserves space for:

- Live Activity Ring
- Current / active task
- Today's actions
- AM summary
- PM summary
- Daily progress
- linked goal

These are intentionally presented as a layout scaffold so the data layer can land later without forcing another structural rewrite.

## Architecture Rules

- Do not show both space navigation groups simultaneously.
- Do not use iOS-only APIs.
- Do not duplicate top-level navigation in multiple places.
- Keep shared UI components independent from destination logic where possible.
- Preserve keyboard and split-view behavior that feels native on macOS.

## Next Growth Path

After the shell is stable, the next step is to replace the mock `Now` content with real domain-backed state and then layer in the remaining destination views one by one.
