# Debug Report: ContentUnavailableView Text Diagnostics

- Symptom: Xcode reported `Cannot convert value of type 'some View' to expected argument type 'Text'` in empty-state views.
- Root cause: `ContentUnavailableView` requires a `Text` description, but applying `.lineSpacing(...)` to `Text` changes the expression's type to `some View`.
- Fix: Removed `.lineSpacing(...)` from all `ContentUnavailableView` description arguments in Now, Calendar, Track, and Timeline views.
- Evidence: Repository scan finds no remaining `description: Text(...).lineSpacing(...)` pattern. `git diff --check` passes.
- Verification: An Xcode build reached Swift compilation without compiler diagnostics, but the environment interrupted subsequent builds during SDK cache preparation. A later attempt also encountered a locked build database from the interrupted process.
- Status: DONE_WITH_CONCERNS
