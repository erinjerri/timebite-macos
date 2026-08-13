import SwiftUI

struct CalendarBlockEditor: View {
    @Environment(\.dismiss) private var dismiss
    let block: ScheduledBlock
    let actualDuration: TimeInterval?
    let onSave: (ScheduledBlock) -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var status: ScheduledBlockStatus

    init(
        block: ScheduledBlock,
        actualDuration: TimeInterval?,
        onSave: @escaping (ScheduledBlock) -> Void,
        onComplete: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.block = block
        self.actualDuration = actualDuration
        self.onSave = onSave
        self.onComplete = onComplete
        self.onDelete = onDelete
        _title = State(initialValue: block.title)
        _startDate = State(initialValue: block.startDate)
        _endDate = State(initialValue: block.endDate)
        _status = State(initialValue: block.status)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Scheduled Block").font(TimeBiteTypography.font(.title2, weight: .semibold))
            TextField("Title", text: $title)
            DatePicker("Starts", selection: $startDate)
            DatePicker("Ends", selection: $endDate, in: startDate...)
            Picker("Status", selection: $status) {
                ForEach(ScheduledBlockStatus.allCases, id: \.self) { value in Text(value.rawValue.capitalized).tag(value) }
            }
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                GridRow { Text("Planned").foregroundStyle(.secondary); Text(max(0, endDate.timeIntervalSince(startDate)).calendarDuration) }
                GridRow { Text("Actual").foregroundStyle(.secondary); Text(actualDuration?.calendarDuration ?? "Not recorded") }
            }
            Divider()
            HStack {
                Button("Delete", role: .destructive) { onDelete(); dismiss() }
                if block.status != .completed {
                    Button("Mark Complete") { onComplete(); dismiss() }
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    var updated = block
                    updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.startDate = startDate
                    updated.resize(to: endDate)
                    updated.status = status
                    onSave(updated)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || endDate <= startDate)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
