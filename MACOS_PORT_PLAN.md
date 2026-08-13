# macOS Port Plan

## Goal

Build a macOS-first TimeBite experience that supports switching between two spaces in one app:

- `TIMEBITE`
- `CREATING YOUR REALITY`

The first working milestone is a native shell plus a functional `Today / Now` screen.

## What Not To Do

- Do not blindly port the iOS UI.
- Do not copy `TimeBiteRootView.swift` as the macOS root.
- Do not recreate the iPhone navigation stack on macOS.
- Do not duplicate the entire source app before extracting shared logic.
- Do not delete or rewrite the working source code.

## Port Strategy

### Phase 1: Establish the shared core

Extract the smallest reusable foundation from the source repository:

- domain models
- persistence contracts
- business rules for today/now selection
- summary aggregation logic

Deliverable:

- a shared layer that macOS can consume without depending on iOS UI

### Phase 2: Build the macOS shell

Create a native macOS navigation shell with:

- top-level app chrome
- space switching
- sidebar or segmented space navigation
- `Now` as the default landing surface

Deliverable:

- the user can move between `TIMEBITE` and `CREATING YOUR REALITY` without leaving the app

### Phase 3: Ship a functional Today / Now screen

The first screen should answer:

- What am I doing now?
- What is today’s focus?
- What is the current state of the plan?
- What needs attention next?

Deliverable:

- a working, data-backed `Now` view

### Phase 4: Expand space-specific surfaces

After the shell is stable, add the other space surfaces:

#### TIMEBITE

- Actions
- Goals
- Plan
- Track
- Dashboard

#### CREATING YOUR REALITY

- Create
- Discover
- Journal
- Library
- Me

## Suggested Implementation Order

1. Shared domain models for plans, goals, reflections, and cycles.
2. Persistence protocol and local store adapter.
3. Current-space app state and space switcher.
4. `Now` view model / presenter.
5. macOS shell view hierarchy.
6. Summary component(s).
7. Space-specific placeholder screens.
8. First real forms and edits for Today / Now.

## Recommended Shape of the macOS Shell

The macOS app should feel like a workspace, not a phone clone.

Suggested structure:

- persistent sidebar for space sections
- primary detail area for the selected surface
- optional inspector or contextual panel later
- strong default focus on `Now`

## Functional First Screen

The first `Now` screen should use a small set of shared inputs:

- active date
- current space
- current plan
- current focus lane or goal
- pending reflection or cycle state

It should produce a concise overview with:

- current priority
- next action
- progress snapshot
- quick entry points

## Reuse Guidance

### Reuse directly

- domain model structs and enums
- storage abstraction and repositories
- logic for derived summaries
- neutral SwiftUI summary components

### Rebuild natively for macOS

- root navigation
- shell layout
- sidebar / space switcher
- screen hierarchy

### Keep as reference only

- phone-first screen compositions
- tab-bar assumptions
- compact list-only layouts

## Early Risks

- Building too many screens before the shell is usable.
- Baking iOS interaction into shared code.
- Conflating conceptual spaces with presentation tabs.
- Treating “Creating Your Reality” as a feature bucket instead of a first-class information space.

## Success Criteria for the First Milestone

- The app opens to a macOS-native shell.
- The user can switch between the two spaces in-app.
- `Now` loads and renders useful data.
- Shared domain and persistence code are isolated from UI.
- No iOS-only screen layout is copied wholesale.

## Files to Implement Next

In order:

1. `Shared/Models/`
2. `Shared/Domain/`
3. `Shared/Persistence/`
4. `Shared/Services/`
5. `Shared/Components/`
6. `macOS/App/TimeBiteMacApp.swift`
7. `macOS/App/RootShellView.swift`
8. `macOS/Features/Now/NowView.swift`
9. `macOS/Features/Now/NowViewModel.swift`
10. `macOS/Features/Spaces/SpaceSwitcherView.swift`
