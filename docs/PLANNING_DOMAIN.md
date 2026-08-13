# Planning Domain

## Domain Chain

```text
Goal
  ↓
Milestone
  ↓
Project
  ↓
Action
  ↓
ScheduledBlock
  ↓
FocusSession
```

The chain describes increasingly concrete planning information, not mandatory ownership. Every parent identifier below `Goal` is optional so an Inbox Action can exist before the user organizes it.

## What, When, and Actual Execution

### WHAT = Action

An `Action` describes something the user wants to accomplish. It can optionally link to a Goal, Milestone, and Project. Its `estimatedDuration` is an estimate, not a calendar event.

### WHEN = ScheduledBlock

A `ScheduledBlock` allocates a specific time range to an Action. Scheduling an Action creates a new block and leaves the Action unchanged.

```text
Action: Build Track UI

ScheduledBlock: Tuesday 2:00–3:00
ScheduledBlock: Wednesday 10:00–11:30
ScheduledBlock: Thursday 3:00–4:00
```

An Action can have zero, one, or many blocks. Deleting a block never deletes its Action. Moving a block preserves its duration. Resizing updates its end date and planned duration. Completing a block does not complete its Action.

`SchedulingDefaults.defaultBlockDuration` provides the one centralized fallback when neither the scheduling request nor Action has a duration estimate.

### ACTUAL EXECUTION = FocusSession

A `FocusSession` records work that actually happened. It can link to a ScheduledBlock and Action. Multiple sessions can contribute actual duration to one block, allowing comparisons such as:

```text
ScheduledBlock.plannedDuration
vs
sum(FocusSession.actualDuration)
```

The model prepares this relationship without duplicating the timer implementation.

## Timeline and Gantt

Goal, Milestone, Project, and Action all support optional `startDate` and `targetDate`. A future Gantt view will visualize these same entities. It must not create Gantt-only copies of the hierarchy.

## Calendar Integration

EventKit events are not persisted as TimeBite ScheduledBlocks.

```text
PlanningRepository ──> ScheduledBlock ─┐
                                      ├─> CalendarItemAdapter ─> Calendar presentation
EventKit adapter ──> External event ──┘
```

`CalendarItem` is presentation data with two variants:

- `.timeBiteBlock(ScheduledBlock)`
- `.externalEvent(ExternalCalendarEvent)`

An eventual EventKit implementation will conform to `ExternalCalendarProviding`, request events for the visible date interval, and merge them in memory. External events are not duplicated into the TimeBite store.

## Persistence

`PlanningRepository` owns Goals, Milestones, Projects, Actions, ScheduledBlocks, and FocusSessions. `LocalPlanningRepository` stores a versioned Codable `PlanningStore` under a dedicated key. This keeps planning data separate from Track/Habit data and from the current SwiftData template.

The repository refuses unknown schema versions rather than deleting or resetting data. Future schema changes must add an explicit migration from the previous `PlanningStore.schemaVersion` before incrementing `currentSchemaVersion`.

No SwiftData schema migration is required for this change because no existing SwiftData models or containers were changed.

## Scheduling Flow

Dragging an Action onto a date eventually calls:

```text
SchedulingService.schedule(action:at:duration:)
```

The service:

1. Uses an explicit duration when supplied.
2. Otherwise uses `Action.estimatedDuration`.
3. Otherwise uses `SchedulingDefaults.defaultBlockDuration`.
4. Creates a new TimeBite ScheduledBlock linked by `actionID`.
5. Does not mutate or replace the Action.

Calendar drag, move, resize, and delete interfaces should call these domain operations rather than recreating their rules in SwiftUI.
