# TimeBite Design System

This file is the shared reference for the macOS TimeBite visual language.
It is intentionally lightweight: enough to keep the app consistent, not a full brand book.

## Design Goals

- macOS-first, workspace-oriented layout
- calm, spacious, and readable
- soft pastel accents instead of saturated neon colors
- clear hierarchy between shell, navigation, and content
- enough structure to feel intentional even with placeholder data

## Color Direction

Primary accent colors:

- `blue` for the main live activity ring and primary live-state emphasis
- `green` for daily progress and completion-oriented emphasis
- `sky` for default selection, emphasis, and secondary chart/ring highlights
- `teal` for secondary action states and supportive emphasis
- `violet` for tertiary or thematic accents
- `gold` for warnings, progress, and warm highlights

Current palette should stay pastel and muted:

- avoid highly saturated neon blues, greens, or reds
- use translucent fills for selected states
- prefer layered surfaces over flat primary-color blocks

## Surface Treatment

- `background` should stay soft and slightly cool
- `surface` should remain clean and neutral
- `elevatedSurface` should be only slightly brighter than surface
- borders should be subtle and low-contrast
- shadows should be soft and restrained

## Typography

Use `League Spartan` through `TimeBiteTypography` for the app shell.

Rules:

- use the shared typography helper instead of ad hoc font sizes
- keep copy a touch larger than the previous baseline; body and supporting text should read closer to 10–12 pt equivalent rather than 8 pt
- reserve stronger weights for titles and selected states
- keep captions small and tracked for section labels

## Navigation

The app shell should feel like a desktop workspace, not an enlarged mobile tab bar.

Navigation patterns:

- centered or top-aligned shell controls when appropriate
- explicit space switching for top-level app areas
- clear selected state treatment without heavy chrome
- avoid dense tab-row visual noise

## Component Behavior

Common interaction rules:

- selected items get a soft tinted background
- primary labels use the default accent color
- secondary supporting content uses muted text
- charts and rings should be readable at a glance
- hover states should remain subtle

## Data Visualization

Use pastel accents for:

- activity rings
- progress charts
- timeline bars
- selected calendar blocks

Prefer:

- clear contrast between planned and actual
- low-noise grid lines
- legend and series colors that remain distinguishable without being loud

## Calendar / Planning

Calendar visual rules:

- scheduled blocks should read as soft pastel cards
- external calendar events should stay visually distinct and neutral
- the current-time indicator should be visible but not aggressive
- selection and drag targets should use tint, not hard outlines

## Implementation Notes

- Use the shared palette from `Shared/Presentation/TimeBitePalette.swift`
- Keep new color values centralized
- Live activity should use blue; daily progress should use green
- When changing highlight colors, update shell chrome and content surfaces together
- Prefer consistency across Plan, Dashboard, Track, and Now rather than per-screen exceptions
