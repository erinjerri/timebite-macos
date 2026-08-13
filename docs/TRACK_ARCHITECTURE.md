# Track Architecture

## Product Boundary

Track answers **“What did I actually do?”** It presents execution history and behavior records. Dashboard will later answer **“Am I progressing?”** by interpreting these records against longer-term goals.

Track does not persist independent weekly, monthly, or annual snapshots. Those views aggregate underlying Daily records so corrections remain consistent everywhere.

```text
DailyTrackingRecord
        |
        v
Daily summary
        |
        +------> Weekly (7 Daily summaries)
        |
        +------> Monthly (calendar of Daily summaries)
        |
        +------> Annual (12 Monthly summaries)
```

## Data, Calculation, Presentation

### Data

- `DailyTrackingRecord` stores planned/completed action counts, goal-linked action counts, planned focus time, tracked activities, and AM/PM reflection values.
- `TrackedActivity` stores an extensible `ActivityCategory`; categories are not restricted to a hard-coded list.
- `Habit` stores the habit definition and optional Life Area/Goal relationships.
- `HabitLog` stores dated values separately from `Habit` so the habit does not accumulate an embedded history array.

The shared models import Foundation only. They do not depend on SwiftUI, AppKit, UIKit, WatchKit, HealthKit, or RealityKit.

### Calculation

- `HabitCompletionCalculator` normalizes boolean, count, duration, and quantity values.
- `TrackingAggregationService` derives Daily, Weekly, and Monthly summaries from source records.
- Annual presentation requests twelve Monthly summaries from the same service.
- `TrackingThresholds` owns calendar checkmark thresholds: achieved at 80% or greater, partial above zero, and no-data otherwise.

Metrics with no supporting source data remain `nil`. The service does not fabricate goal completions, milestones, or other productivity scores.

### Persistence

```text
HabitRepository       TrackingRepository
       |                       |
       +-----------+-----------+
                   |
         LocalTrackingRepository
```

`LocalTrackingRepository` currently uses Codable values in `UserDefaults` for the first macOS version. Repository protocols allow a future shared SwiftData, CloudKit, or server-backed implementation without changing Track views or calculations.

## Habit Flow

```text
Habit
  |
  v
HabitLog (one dated value)
  |
  v
TrackingAggregationService
  |
  +--> Track / Habits
  +--> Daily, Weekly, Monthly, Annual
  +--> Dashboard later
```

Supported tracking types:

- Boolean: completion is either zero or one.
- Count: progress is value divided by target count.
- Duration: progress is duration divided by target duration.
- Quantity: progress is measured quantity divided by target quantity.

Normalized display progress clamps to `0...1`; raw log values remain intact.

## Views

- **Daily**: alignment ring, Focus/Actions/Goals/Reflection components, actual activity timeline, AM summary, and PM summary.
- **Weekly**: seven clickable Daily rings and aggregate supported totals.
- **Monthly**: calendar/checkmark visualization with Overall, Goal, Habit, Focus, and Actions metrics. It is intentionally not a heatmap.
- **Annual**: twelve meaningful Monthly cards rather than 365 small cells.
- **Habits**: Week/Month logging grid and persistent habit creation.

Selecting a day in Weekly or Monthly updates the shared selected date and opens Daily. Preview data is injected only by SwiftUI previews; production uses persisted records and displays explicit zero/empty states when none exist.

## Deferred Integrations

- Import existing iOS `CycleLog`, `FocusLane`, `DailyPlan`, and `Reflection` records through a repository adapter.
- Shared Life Area and Goal pickers once those cross-platform IDs and repositories exist.
- Numeric partial-value entry in the habit grid; the first version toggles zero or the target value.
- Weekly reflection persistence.
- Dashboard interpretation and trend analysis.
