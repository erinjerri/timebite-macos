import SwiftUI

struct TimeBiteCalendarView: View {
    @StateObject private var model: CalendarViewModel

    init(previewStore: PlanningStore? = nil) {
        _model = StateObject(wrappedValue: CalendarViewModel(previewStore: previewStore))
    }

    var body: some View {
        VStack(spacing: 0) {
            calendarToolbar
            Divider()
            HStack(spacing: 0) {
                CalendarActionSidebar(model: model)
                    .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
                Divider()
                VStack(spacing: 0) {
                    permissionBanner
                    CalendarTimeGrid(model: model)
                }
                .frame(minWidth: 680)
            }
        }
        .task { await model.loadExternalEvents(requestAccess: false) }
        .sheet(item: $model.selectedBlock) { block in
            CalendarBlockEditor(
                block: block,
                actualDuration: model.actualDuration(for: block),
                onSave: model.saveBlock,
                onComplete: { model.complete(block) },
                onDelete: { model.delete(block) }
            )
        }
        .alert("Calendar error", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) { Button("OK") { model.errorMessage = nil } } message: { Text(model.errorMessage ?? "") }
    }

    private var calendarToolbar: some View {
        HStack(spacing: 12) {
            Button { model.navigate(-1) } label: { Image(systemName: "chevron.left") }
                .help("Previous \(model.mode.title.lowercased())")
                .accessibilityLabel("Previous \(model.mode.title)")
            Button("Today") { model.goToToday() }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            Button { model.navigate(1) } label: { Image(systemName: "chevron.right") }
                .help("Next \(model.mode.title.lowercased())")
                .accessibilityLabel("Next \(model.mode.title)")
            Text(model.dateRangeTitle)
                .font(TimeBiteTypography.font(.title3, weight: .semibold))
                .padding(.leading, 8)
            Spacer()
            Picker("Calendar mode", selection: $model.mode) {
                ForEach(CalendarMode.allCases) { mode in Text(mode.title).tag(mode) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 170)
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 20)
        .frame(height: 54)
    }

    @ViewBuilder
    private var permissionBanner: some View {
        switch model.calendarAuthorization {
        case .notDetermined:
            HStack {
                Label("Show Apple Calendar events alongside TimeBite blocks", systemImage: "calendar.badge.plus")
                Spacer()
                Button("Connect Calendar") { Task { await model.loadExternalEvents(requestAccess: true) } }
            }
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(TimeBitePalette.sky.opacity(0.08))
        case .denied, .restricted:
            HStack {
                Label("Calendar access is unavailable. TimeBite scheduling still works.", systemImage: "calendar.badge.exclamationmark")
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .frame(height: 38)
        case .authorized, .unavailable:
            EmptyView()
        }
    }
}

#Preview {
    TimeBiteCalendarView(previewStore: .calendarPreview())
        .frame(width: 1450, height: 900)
}
