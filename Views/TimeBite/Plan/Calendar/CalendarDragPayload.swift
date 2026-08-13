import CoreTransferable
import Foundation
import UniformTypeIdentifiers

enum CalendarDragKind: String, Codable {
    case action
    case scheduledBlock
}

struct CalendarDragPayload: Codable, Transferable {
    var kind: CalendarDragKind
    var id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .timeBiteCalendarDrag)
    }
}

extension UTType {
    static let timeBiteCalendarDrag = UTType(exportedAs: "com.erinjerri.timebite.calendar-drag")
}
