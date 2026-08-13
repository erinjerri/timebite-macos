# Shared Architecture

## Objective

Create a shared foundation that supports multiple Apple platforms without forcing the same UI everywhere.

The long-term shape should be:

- `Shared/Models/`
- `Shared/Domain/`
- `Shared/Persistence/`
- `Shared/Services/`
- `Shared/Components/`
- `macOS/`
- `iOS/`
- `watchOS/`
- `visionOS/`

## Why This Structure Works

TimeBite has two different kinds of product surface:

1. A shared conceptual system:
   - goals
   - plans
   - reflections
   - cycles
   - daily focus
2. Platform-specific presentation:
   - macOS workspace shell
   - iOS compact navigation
   - watchOS glanceability
   - visionOS spatial presentation

The shared architecture should maximize reuse in category 1 and minimize accidental reuse in category 2.

## Proposed Layers

### Shared/Models

Plain data types and enums.

Examples:

- `DailyPlan`
- `FocusLane`
- `FocusLaneType`
- `Reflection`
- `ReflectionStatus`
- `CycleLog`

Responsibilities:

- identity
- codability
- equatability
- ordering
- derived values that are intrinsic to the model

### Shared/Domain

Pure business rules and use cases.

Examples:

- pick current focus
- compute plan status
- determine next suggested action
- summarize today’s state
- evaluate reflection completion

Responsibilities:

- no UI dependencies
- no platform dependencies
- deterministic logic
- testable in isolation

### Shared/Persistence

Repository interfaces and storage adapters.

Examples:

- `PlanRepository`
- `ReflectionRepository`
- `CycleRepository`
- `CurrentStateStore`

Responsibilities:

- load/save/delete
- data migration
- store configuration
- schema evolution

### Shared/Services

Orchestration and integrations.

Examples:

- summary builders
- timeline coordinators
- import/export
- sync pipelines

Responsibilities:

- coordinate domain + persistence
- expose use-case level APIs
- stay UI-agnostic

### Shared/Components

Reusable SwiftUI or presentation-neutral UI pieces.

Examples:

- summary cards
- stat rows
- status chips
- chart wrappers
- empty states

Responsibilities:

- visual reuse only
- no navigation ownership
- no app-shell assumptions

## Platform Folders

### macOS/

Mac-first app shell and workspace layout.

Should contain:

- app entry point
- sidebar navigation
- root shell
- macOS-specific `Now` and space views
- inspector or utility window support later if needed

### iOS/

Compact phone experience.

Should contain:

- iPhone-appropriate navigation
- compact editing flows
- notification and device-specific integrations

### watchOS/

Glance-first surfaces.

Should contain:

- quick status
- single-action confirmations
- minimal summaries

### visionOS/

Spatial and immersive surfaces.

Should contain:

- volumetric or spatial presentation
- larger conceptual canvases
- gaze-friendly interactions

## Dependency Direction

The dependency flow should stay one-way:

`Platform UI -> Shared/Components -> Shared/Services -> Shared/Domain -> Shared/Models`

And:

`Shared/Persistence` should depend on `Shared/Models`, but not on platform UI.

## What Belongs In The Shared Swift Package

The shared Swift Package should eventually include:

- domain models
- validation and derivation logic
- repositories and storage contracts
- summary builders
- formatting helpers
- neutral reusable components

The package should not include:

- platform app entry points
- scene management
- navigation stacks
- device-specific permission flows

## Recommended Initial Package Boundary

Start narrow.

The first package should include only:

- models
- core domain logic
- read/write persistence interfaces
- a few reusable summary components

That gives the macOS app enough to become functional without overcommitting to a large cross-platform refactor.

## Suggested Module Shape

One practical shape:

```text
Shared/
  Models/
  Domain/
  Persistence/
  Services/
  Components/
macOS/
  App/
  Features/
iOS/
  App/
  Features/
watchOS/
  App/
  Features/
visionOS/
  App/
  Features/
```

## Shared Vs Platform-Specific Rules

### Shared

- business meaning
- state derivation
- data schema
- formatting helpers
- neutral presentation primitives

### Platform-specific

- navigation
- windowing
- gestures
- app lifecycle
- permissions
- input affordances

## Best First Reuse Targets

The best first shared targets from the current source surface are:

1. `DailyPlan`
2. `FocusLane`
3. `FocusLaneType`
4. `Reflection`
5. `ReflectionStatus`
6. `CycleLog`
7. current-day selection logic
8. summary aggregation logic
9. neutral dashboard components

## Final Recommendation

Build the shared package around the domain, not around the screens.

That will let macOS become native, keep iOS intact, and leave room for watchOS and visionOS without forcing every platform into the same UI shape.
