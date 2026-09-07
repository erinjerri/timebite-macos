# Master Roadmap Planning

Status: Planning
Branch: `codex/master-roadmap-planning`
Repository: [timebite-macos](https://github.com/erinjerri/timebite-macos)
Updated: 2026-09-06

## Intent

Replace the current task-centric timeline experience with a portfolio-level Master Roadmap. The default view should answer what matters across the portfolio, what is active next, what is blocked, and which dates or dependencies need attention. It should not expose every execution task in the bird's-eye view.

## Current Architecture

The existing timeline is a SwiftUI presentation over the shared planning domain:

```text
PlanningRepository
  -> Goal -> Milestone -> Project -> Action
  -> TimelineService.hierarchy()
  -> TimelineNode / TimelineRow
  -> TimelineViewModel
  -> Month / Quarter canvas
```

- `Goal`, `Milestone`, `Project`, and `Action` already have optional start and target dates.
- `TimelineNode` is derived data; visual coordinates are not persisted.
- Moving a bar shifts both dates; resizing changes one date through `TimelineService`.
- The current view supports only Month and Quarter scales and renders the expanded hierarchy, including Actions.
- Dependencies, portfolio states, confidence, WIP policy, and repo/codebase metadata do not yet exist in the planning model.

## Proposed Product Shape

### Hierarchy

```text
Portfolio
  -> Area / Venture
    -> Product / Codebase
      -> Project / Epic
        -> Milestone
          -> Task
```

At portfolio level, show Areas and project rows. Tasks remain available after opening a project, preserving a clear separation between roadmap and execution views.

### Default Portfolio View

- Left: collapsible hierarchy outline with Area and project rows.
- Right: time canvas with project windows, milestone markers, deadline risk, and optional dependency edges.
- Above canvas: model-derived summary strip for total projects, active work, next work, blocked work, and shipped work.
- Top controls: `MASTER ROADMAP`, `NOW`, `6 WEEKS`, `QUARTER`, `YEAR`, `ALL`, Today, filters, and dependency visibility.
- Default zoom: Quarter.
- Parked work is hidden by default and available through an explicit filter.

### Project Row Contract

Each portfolio project row should be able to show:

- Name, Area, state, priority (`P0` through `P3`), next milestone, target date, confidence, and progress.
- Optional owner, repository/codebase indicator, and dependency indicator.
- Semantic states: Active, Next, Waiting, Blocked, Parked, Shipped, Maintenance.

## Model Direction

Extend the shared planning domain with explicit portfolio concepts instead of encoding them in SwiftUI-only state:

- `PortfolioArea` or an equivalent venture/product grouping.
- Project portfolio state, priority, confidence, owner, repo/codebase reference, and protected-track metadata.
- Dependency edges between stable planning entity identifiers.
- Derived roadmap summaries and WIP warnings calculated from repository data.
- A view model that supports filters, critical-path projection, collapsed groups, zoom intervals, and reversible timeline edits.

Keep the existing date-editing rule: persist domain dates through `PlanningRepository`; never persist pixel coordinates. Add migrations before changing the persisted `PlanningStore` schema version.

## Delivery Slices

1. Document and test the roadmap projection over current Goal/Milestone/Project data.
2. Add portfolio metadata and persistence migrations.
3. Add `MasterRoadmapViewModel` with zoom, filters, WIP summary, and critical-path derivation.
4. Build the portfolio-level outline and timeline canvas without rendering task-level rows.
5. Add project expansion into milestone/task execution detail.
6. Add drag/resize, milestone editing, dependency visibility, undo, and accessibility coverage.
7. Validate at narrow and wide macOS window sizes with seeded dogfood data.

## Open Decisions

- Whether `Area`, `Venture`, `Product`, and `Codebase` should be separate persisted entities or lightweight project metadata.
- Whether project dependencies should support only finish-to-start initially.
- How confidence is entered and recalculated from schedule variance, dependency state, and completion progress.
- Whether the existing `Goal` should map to Portfolio or Area in the first migration.
- Which external repositories, if any, should be linked through a stable URL versus a local codebase identifier.

## Acceptance Criteria

- The default screen communicates portfolio focus within a few seconds.
- Portfolio rows show meaningful state and date information without task-level noise.
- Quarter, Year, and All views remain readable and use bounded rendering.
- Critical-path and WIP signals are derived from model data, not hardcoded labels or counts.
- Existing timeline entities and date edits remain compatible or are migrated safely.
- The project detail view is the deliberate entry point for epics, milestones, and tasks.
