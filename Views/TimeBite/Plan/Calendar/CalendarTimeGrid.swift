import SwiftUI

struct CalendarTimeGrid: View {
    @ObservedObject var model: CalendarViewModel
    private let hourHeight: CGFloat = 64
    private let timeColumnWidth: CGFloat = 62

    var body: some View {
        GeometryReader { proxy in
            let dayWidth = model.mode == .day ? max(proxy.size.width - timeColumnWidth, 720) : 176
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    dayHeaders(dayWidth: dayWidth)
                    HStack(alignment: .top, spacing: 0) {
                        timeAxis
                        ForEach(model.visibleDates, id: \.self) { date in
                            CalendarDayColumn(model: model, date: date, width: dayWidth, hourHeight: hourHeight)
                        }
                    }
                }
            }
            .background(.primary.opacity(0.018))
        }
    }

    private func dayHeaders(dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: timeColumnWidth, height: 58)
            ForEach(model.visibleDates, id: \.self) { date in
                VStack(spacing: 3) {
                    Text(date, format: .dateTime.weekday(.abbreviated))
                        .font(TimeBiteTypography.font(.caption, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(date, format: .dateTime.day())
                        .font(TimeBiteTypography.font(.title3, weight: Calendar.current.isDateInToday(date) ? .bold : .medium))
                        .foregroundStyle(Calendar.current.isDateInToday(date) ? TimeBitePalette.sky : .primary)
                }
                .frame(width: dayWidth, height: 58)
                .overlay(alignment: .leading) { Divider() }
                .background(Calendar.current.isDateInToday(date) ? TimeBitePalette.sky.opacity(0.045) : .clear)
            }
        }
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var timeAxis: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear.frame(width: timeColumnWidth, height: hourHeight * 24)
            ForEach(0..<24, id: \.self) { hour in
                Text(hourLabel(hour))
                    .font(TimeBiteTypography.font(.caption2))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
                    .offset(y: CGFloat(hour) * hourHeight - 6)
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

private struct CalendarDayColumn: View {
    @ObservedObject var model: CalendarViewModel
    let date: Date
    let width: CGFloat
    let hourHeight: CGFloat
    private let calendar = Calendar.current

    var body: some View {
        ZStack(alignment: .topLeading) {
            gridLines
            ForEach(model.externalEvents(on: date)) { event in
                ExternalEventBlock(event: event, hourHeight: hourHeight)
                    .padding(.horizontal, 4)
                    .frame(width: width)
            }
            ForEach(model.blocks(on: date)) { block in
                TimeBiteBlockView(block: block, model: model, hourHeight: hourHeight)
                    .padding(.horizontal, 5)
                    .frame(width: width)
            }
            if calendar.isDateInToday(date) {
                currentTimeIndicator
            }
        }
        .frame(width: width, height: hourHeight * 24, alignment: .topLeading)
        .background(calendar.isDateInToday(date) ? TimeBitePalette.sky.opacity(0.025) : .clear)
        .overlay(alignment: .leading) { Divider() }
        .dropDestination(for: CalendarDragPayload.self) { payloads, location in
            guard let payload = payloads.first else { return false }
            let rawMinutes = Int((location.y / hourHeight) * 60)
            let snapped = min(23 * 60 + 45, max(0, Int((Double(rawMinutes) / 15).rounded()) * 15))
            model.handleDrop(payload, on: date, minuteOfDay: snapped)
            return true
        }
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
    }

    private var gridLines: some View {
        ZStack(alignment: .top) {
            ForEach(0...24, id: \.self) { hour in
                Rectangle()
                    .fill(.primary.opacity(hour % 6 == 0 ? 0.12 : 0.065))
                    .frame(height: 1)
                    .offset(y: CGFloat(hour) * hourHeight)
            }
            ForEach(0..<24, id: \.self) { hour in
                Rectangle()
                    .fill(.primary.opacity(0.025))
                    .frame(height: 1)
                    .offset(y: CGFloat(hour) * hourHeight + hourHeight / 2)
            }
        }
    }

    private var currentTimeIndicator: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let components = calendar.dateComponents([.hour, .minute], from: context.date)
            let minute = CGFloat((components.hour ?? 0) * 60 + (components.minute ?? 0))
            let tint = Color(red: 0.95, green: 0.62, blue: 0.70)
            HStack(spacing: 0) {
                Circle().fill(tint).frame(width: 7, height: 7)
                Rectangle().fill(tint).frame(height: 1)
            }
            .frame(width: width)
            .offset(y: minute / 60 * hourHeight - 3)
            .accessibilityLabel("Current time")
        }
    }
}

private struct TimeBiteBlockView: View {
    let block: ScheduledBlock
    @ObservedObject var model: CalendarViewModel
    let hourHeight: CGFloat
    @State private var hovering = false

    var body: some View {
        let height = max(28, CGFloat(block.plannedDuration / 3600) * hourHeight)
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(block.title).font(TimeBiteTypography.font(.callout, weight: .semibold)).lineLimit(1)
                Spacer(minLength: 2)
                if block.status == .completed { Image(systemName: "checkmark") }
            }
            Text("\(block.startDate.formatted(date: .omitted, time: .shortened)) · \(block.plannedDuration.calendarDuration)")
                .font(TimeBiteTypography.font(.caption2))
                .opacity(0.8)
            if let actual = model.actualDuration(for: block), height > 55 {
                Text("Actual \(actual.calendarDuration)").font(TimeBiteTypography.font(.caption2)).opacity(0.8)
            }
            Spacer(minLength: 0)
            Capsule().fill(.white.opacity(0.65)).frame(width: 28, height: 3).frame(maxWidth: .infinity)
                .contentShape(Rectangle().inset(by: -8))
                .gesture(DragGesture(minimumDistance: 2).onEnded { value in
                    model.resize(block, by: Int((value.translation.height / hourHeight) * 60))
                })
                .help("Drag to resize")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(height: height, alignment: .topLeading)
        .foregroundStyle(Color(red: 0.02, green: 0.12, blue: 0.18))
        .background(
            LinearGradient(colors: [TimeBitePalette.sky, TimeBitePalette.teal.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
        .shadow(color: .black.opacity(hovering ? 0.18 : 0.08), radius: hovering ? 8 : 3, y: 2)
        .scaleEffect(hovering ? 1.01 : 1)
        .offset(y: verticalOffset(block.startDate))
        .contentShape(Rectangle())
        .onTapGesture { model.selectedBlock = block }
        .onHover { hovering = $0 }
        .draggable(CalendarDragPayload(kind: .scheduledBlock, id: block.id))
        .help("Drag to move. Click to edit.")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("TimeBite block, \(block.title), \(block.startDate.formatted(date: .omitted, time: .shortened)), planned \(block.plannedDuration.calendarDuration)")
        .accessibilityAction(named: "Edit") { model.selectedBlock = block }
    }

    private func verticalOffset(_ date: Date) -> CGFloat {
        let values = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat((values.hour ?? 0) * 60 + (values.minute ?? 0)) / 60 * hourHeight
    }
}

private struct ExternalEventBlock: View {
    let event: ExternalCalendarEvent
    let hourHeight: CGFloat

    var body: some View {
        let duration = max(15 * 60, event.endDate.timeIntervalSince(event.startDate))
        VStack(alignment: .leading, spacing: 3) {
            Label(event.title, systemImage: "calendar")
                .font(TimeBiteTypography.font(.callout, weight: .semibold))
                .lineLimit(1)
            Text(event.startDate.formatted(date: .omitted, time: .shortened))
                .font(TimeBiteTypography.font(.caption2))
        }
        .padding(7)
        .frame(height: max(28, CGFloat(duration / 3600) * hourHeight), alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        .offset(y: verticalOffset(event.startDate))
        .help("External calendar event. TimeBite will not modify it.")
        .accessibilityLabel("External calendar event, \(event.title)")
    }

    private func verticalOffset(_ date: Date) -> CGFloat {
        let values = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat((values.hour ?? 0) * 60 + (values.minute ?? 0)) / 60 * hourHeight
    }
}
