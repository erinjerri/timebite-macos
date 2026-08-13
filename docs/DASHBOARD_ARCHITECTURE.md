# TimeBite Dashboard Architecture

## Purpose Boundaries

```text
Timeline  = intended planning trajectory
Dashboard = observed progress and execution
Track     = historical behavioral record
```

Dashboard never edits planning data and does not maintain a second analytics store.

## Pipeline

```text
Goal / Action
      +
ScheduledBlock
      +
FocusSession
      +
DailyTrackingRecord / HabitLog
      |
      v
DashboardAggregationService
      |
      v
DashboardMetrics
      |
      v
DashboardViewModel
      |
      v
Overview / Progress / future Goals, Time, Trends
```

## Transparent Calculations

TimeBite does not calculate a proprietary AI productivity score.

V1 component metrics are independent and explicitly labeled:

- **Category progress point:** total actual tracked duration divided by total planned duration for the category and date. A point exists only when planned duration is greater than zero. Display values clamp to `0...1`; source duration remains unchanged.
- **Goal-linked actions:** completed Goal-linked Actions divided by all Goal-linked Actions.
- **Habit consistency:** mean normalized completion for recorded active-habit logs in the selected interval.
- **Planned vs actual:** completed Focus Session duration divided by non-cancelled ScheduledBlock planned duration in the selected interval.
- **Focused time:** completed Focus Sessions when present, otherwise recorded tracked activity duration.
- **Actions completed:** sum from DailyTrackingRecords in the selected interval.

Metrics without sufficient inputs are omitted. When no comparable category data exists, Progress explains that both planned and actual duration are required.

## Progress Series

Series are discovered from `ActivityCategory`, allowing existing or future Focus Lane adapters to supply custom categories. Career, Health, or other names are preview data, not immutable product taxonomy.

The selected range is bounded to 7, 30, 90, 180, or 365 days. Series visibility and selected chart date are view-model presentation state and are not persisted as analytics.

## External and Future Inputs

Future Focus Lane aggregation should adapt lane records into Dashboard inputs rather than hard-code six categories. External calendar events are not productivity evidence and should not affect progress unless an explicit product rule creates a supported execution record.

## Cross-Platform Boundary

`DashboardRange`, `DashboardMetrics`, and `DashboardAggregationService` use Foundation only and should move into the future shared package for iOS, watchOS, and visionOS. Swift Charts composition, hover behavior, and desktop layout remain platform presentation.
