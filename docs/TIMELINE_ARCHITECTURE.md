# TimeBite Timeline Architecture

## Purpose

Timeline answers: **What is supposed to happen, and when?**

It is a planning interface over the existing hierarchy:

```text
Goal
  -> Milestone
    -> Project
      -> Action
```

Timeline does not introduce `GanttGoal`, `GanttProject`, visual-coordinate storage, or an analytics datastore.

## Data Flow

```text
PlanningRepository
  -> Goal / Milestone / Project / Action
  -> TimelineService.hierarchy()
  -> TimelineNode (derived view data)
  -> TimelineViewModel
  -> Month / Quarter canvas
```

`TimelineNode` is transient hierarchy data. Its identifier points back to exactly one existing planning entity.

## Date Editing

Moving a bar offsets both `startDate` and `targetDate`. Resizing an edge updates only the corresponding date. `TimelineService` saves the changed Goal, Milestone, Project, or Action through `PlanningRepository`.

No pixel positions are stored. The UI calculates positions from the visible `DateInterval` every time it renders.

Items without both dates remain in the hierarchy and display a `No dates` state rather than receiving fabricated dates.

## Scale and Performance

V1 supports Month and Quarter. Month uses weekly grid markers; Quarter uses monthly markers. The view renders only one bounded interval and the currently expanded hierarchy.

Week and Year can be added by extending `TimelineScale` and interval/grid generation. Year should use month or quarter markers rather than hundreds of daily columns.

## Dependencies

Dependencies are intentionally deferred. A future dependency model should reference domain entity identifiers and live beside planning domain types. It should not be encoded as lines or coordinates in the Timeline UI.

## Cross-Platform Boundary

`TimelineModels` and `TimelineService` depend only on Foundation and belong in a future shared package. The macOS canvas, gestures, and inspector remain platform presentation code.
