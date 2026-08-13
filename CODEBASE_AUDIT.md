# Codebase Audit

## Scope

This audit is based on:

- The existing macOS target repository in this workspace.
- The source repository file areas called out by the user:
  - `apps/iOS/Views/`
  - `apps/iOS/Models/`
  - `apps/iOS/ViewModels/`
  - `apps/iOS/Managers/`
  - `apps/iOS/Persistence/`
  - `apps/iOS/Spatial/`
- The named source types and views:
  - `DailyPlan`
  - `FocusLane`
  - `FocusLaneType`
  - `Reflection`
  - `ReflectionStatus`
  - `CycleLog`
  - `ActionsView.swift`
  - `GoalsView.swift`
  - `QuarterlyGoalChartView.swift`
  - `ReflectionView.swift`
  - `SpatialDashboardSummaryView.swift`
  - `TimeBiteRootView.swift`

I did not copy any iOS source code into the macOS target. The goal here is classification and migration planning, not a visual port.

## Target Repository State

The macOS repo currently contains only a starter SwiftUI app:

- `ContentView.swift`
- `timebite_macosApp.swift`
- `Item.swift`
- asset catalogs and test targets

This means the macOS implementation is still at the scaffold stage. There is no existing domain layer, no persistence abstraction, and no multi-space shell yet.

## Classification Summary

### 1. Reusable domain/model logic

These are the source concepts that should be kept independent of iOS UI and moved into shared model code first:

- `DailyPlan`
- `FocusLane`
- `FocusLaneType`
- `Reflection`
- `ReflectionStatus`
- `CycleLog`

Likely reusable behavior hidden inside these types:

- Validation rules
- Status transitions
- Ordering and grouping logic
- Date-based computations
- Derived metrics and summaries
- Serialization / decoding behavior

### 2. Reusable persistence

The persistence layer should be split away from any SwiftUI view code or iOS-specific storage entry points.

Likely reusable pieces:

- Storage schemas for the domain models above
- CRUD/repository APIs
- Migration helpers
- Query / fetch helpers
- Local cache orchestration
- Any SwiftData/Core Data wrappers that are not tied to a specific screen

If the source uses SwiftData, this is the first place where shared code should be extracted so both macOS and iOS can rely on the same persistence contracts.

### 3. Reusable business logic

These should become platform-neutral services or domain use cases:

- Daily planning rules
- Goal progress calculations
- Reflection completion and status handling
- Spatial dashboard rollups
- Timeline / cycle summaries
- “what should be shown now” selection logic
- Any orchestration currently living in view models or managers

Likely source locations to mine for this logic:

- `apps/iOS/ViewModels/`
- `apps/iOS/Managers/`
- parts of `apps/iOS/Spatial/`

### 4. Reusable SwiftUI components

These are visual building blocks that can likely survive a macOS migration with adaptation:

- Row and card primitives
- Status badges
- Summary tiles
- Goal progress visualizations
- Simple chart containers
- Empty states
- Common section headers
- Shared navigation chrome used by both spaces

From the named files, the most likely reusable UI component candidate is:

- `SpatialDashboardSummaryView.swift`

If `QuarterlyGoalChartView.swift` is mostly a chart presentation wrapper rather than screen-level navigation, it may also be reusable as a component.

### 5. iOS-specific UI that should NOT be copied

These are the source views most likely to be tightly coupled to iPhone interaction patterns, compact layouts, or iOS-only navigation assumptions:

- `ActionsView.swift`
- `GoalsView.swift`
- `ReflectionView.swift`
- `TimeBiteRootView.swift`

These views may still be useful as reference material for content and hierarchy, but they should not be ported literally.

Why they should not be copied as-is:

- Their layout is probably optimized for a single-column phone screen.
- Their navigation model likely assumes iOS tab or push navigation.
- Their density and interaction affordances may not suit a macOS-first shell.
- The new app needs a space switcher, not a cloned phone tab bar.

### 6. Code that should eventually become a shared Swift Package

The strongest candidates for a future shared package are:

- All domain models listed above
- Persistence contracts and repositories
- Shared business rules and reducers/use cases
- Cross-platform SwiftUI components that are not layout-specific
- Shared formatting, date, and measurement helpers
- Shared state machines for plan/reflection/cycle lifecycle

This package should grow toward a structure like:

- `Shared/Models`
- `Shared/Domain`
- `Shared/Persistence`
- `Shared/Services`
- `Shared/Components`

## Source Area Assessment

### `apps/iOS/Models/`

This is the highest-value source area to extract first.

Most likely includes:

- Data models
- Enums
- Codable / identifiable conformance
- Derived properties
- Lightweight invariant enforcement

These files should be split into:

- truly shared domain models
- storage-specific model adapters
- iOS-only model helpers if any exist

### `apps/iOS/ViewModels/`

This area is likely mixed.

Keep:

- State derivation from domain data
- Current-day selection logic
- summary builders
- reusable navigation or coordination logic

Do not keep:

- Screen-specific `@State` orchestration that exists only to drive iOS views
- one-off UI gestures or interaction handlers
- view presentation logic that depends on a phone layout

### `apps/iOS/Managers/`

This is likely where the business logic is hiding.

Usually reusable:

- scheduling
- selection / prioritization
- persistence coordination
- domain event processing
- sync and import/export logic

Usually not reusable as-is:

- UIKit / iOS notifications
- device-only integrations
- permission prompts or share-sheet behavior

### `apps/iOS/Persistence/`

This should be split into a shared persistence abstraction and a platform-specific store adapter.

Likely reusable:

- schema definitions
- repository protocols
- migration and seed data

Likely not directly reusable:

- App lifecycle wiring
- iOS app group / scene specific setup
- platform-specific store bootstrap code

### `apps/iOS/Spatial/`

This area sounds conceptually valuable but probably visually overfit to the current iOS experience.

What should be preserved:

- the spatial information architecture itself
- summary aggregation logic
- conceptual grouping of work, identity, goals, and daily execution

What should not be copied blindly:

- exact screen structure
- existing spatial navigation assumptions
- any phone-first visual composition

### `apps/iOS/Views/`

This is the least portable layer.

Use it as:

- a source of domain naming
- a source of content grouping ideas
- a source of reusable subviews where they are truly neutral

Do not use it as:

- a template for the macOS shell
- a direct layout guide
- a signal that the same navigation should be recreated

## What MacOS Needs First

The smallest reusable pieces needed for the macOS shell and a functional Today / Now screen are:

1. A shared domain model for current-day planning and reflection state.
2. A persistence abstraction that can load today’s items and save quick edits.
3. A small business-logic layer that answers:
   - What space am I in?
   - What is the current “Now” item?
   - What should show in Today / Now?
4. A reusable summary component for the top-of-screen status.
5. A macOS shell that switches between:
   - `TIMEBITE`
   - `CREATING YOUR REALITY`

## Recommended Migration Principles

- Extract data and rules before UI.
- Build the space switcher before screen parity.
- Treat iOS screen compositions as reference, not source of truth.
- Prefer one shared model layer over duplicated model definitions.
- Keep macOS navigation native to macOS.
- Make Today / Now functional before broad feature parity.

## Primary Risk Areas

- Over-porting iOS navigation into macOS.
- Duplicating the same model in two places.
- Putting persistence queries directly into views.
- Allowing “Spatial” to become a visual clone instead of a conceptual system.
- Recreating every screen before the shell is stable.

## Bottom Line

The reusable core is the domain, persistence contracts, and business logic behind plans, goals, reflections, and cycle tracking. The iOS views themselves are mostly reference material and should not be copied wholesale. The first macOS milestone should be a native shell with space switching and a usable `Now` surface backed by shared domain logic.
