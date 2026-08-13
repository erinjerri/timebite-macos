# Calendar Architecture

## Product Boundary

Calendar answers **“When am I going to work on this?”** Actions answer **“What do I need to do?”** TimeBite preserves that distinction in persistence and interaction design.

```text
Action
  |
  | native drag payload (actionID)
  v
Calendar drop date and time
  |
  v
CalendarSchedulingService
  |
  v
ScheduledBlock
```

Dropping an Action creates a new ScheduledBlock linked through `actionID`. It never converts, replaces, completes, or removes the Action. The same Action can create any number of blocks.

## Duration Resolution

`CalendarSchedulingService` delegates block creation to `SchedulingService`:

1. Use an explicitly supplied duration.
2. Otherwise use `Action.estimatedDuration`.
3. Otherwise use `SchedulingDefaults.defaultBlockDuration`.

The Calendar UI does not contain its own fallback duration.

## Block Operations

- **Move:** dragging an existing block sends a block ID and destination time to `moveBlock`.
- **Resize:** the lower resize handle snaps the duration to 15-minute increments and calls `resizeBlock`.
- **Edit:** the details sheet edits title, start, end, and block status.
- **Complete:** changes only `ScheduledBlock.status`.
- **Delete:** removes only the ScheduledBlock. Its linked Action remains in `PlanningRepository`.

Planned time comes from `ScheduledBlock.plannedDuration`. Actual time comes from linked FocusSessions or an explicitly stored block actual duration. The UI displays “Not recorded” when neither exists.

## Visible Range

The Calendar has bounded modes:

- Day loads one day.
- Week loads seven days and is the default desktop mode.
- Month is reserved in the architecture but intentionally not rendered yet.

Previous, Today, and Next navigation update the bounded interval and reload external events only for that interval. The grid does not render an infinite date range.

## EventKit

```text
EventKit
  |
  v
EventKitCalendarProvider
  |
  v
ExternalCalendarEvent
  |
  v
CalendarItemAdapter / Calendar UI
```

`EventKitCalendarProvider` requests full event access only after the person selects **Connect Calendar**. This access level is required to read events. The app includes the calendar sandbox entitlement and usage description.

Denied or restricted access returns an empty external event collection while TimeBite scheduling remains functional.

External events:

- are visually distinct with neutral, dashed blocks;
- are never persisted in `PlanningStore`;
- never become Actions or ScheduledBlocks;
- have no edit, delete, or write operation in this Calendar implementation.

## Drag and Drop

`CalendarDragPayload` is a small native `Transferable` containing a UUID and kind:

- `.action`
- `.scheduledBlock`

Day columns convert the local drop Y coordinate into a bounded, 15-minute calendar time. Action drops create blocks; block drops move blocks. The source Action remains available according to the selected sidebar filter.

## Desktop and Accessibility

- Resizable split workspace with a 260-point minimum action rail and 680-point minimum calendar.
- Scrollable 24-hour vertical axis and horizontal week columns.
- Keyboard-accessible navigation and Today command.
- VoiceOver labels for Actions, days, blocks, external events, and navigation.
- Hover feedback, tooltips, selection, editing, and a live current-time indicator.

## Deferred

- Month mode.
- Overlap lane packing for heavily concurrent calendars.
- All-day event strip.
- Explicit user-driven write/export to Apple Calendar.
- Kanban, Timeline, and Gantt interfaces.
