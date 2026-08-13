import Foundation

protocol HabitRepository {
    func habits() throws -> [Habit]
    func save(_ habit: Habit) throws
}

protocol TrackingRepository {
    func dailyRecords() throws -> [DailyTrackingRecord]
    func habitLogs() throws -> [HabitLog]
    func save(_ log: HabitLog) throws
}

final class LocalTrackingRepository: HabitRepository, TrackingRepository {
    private enum Key {
        static let habits = "timebite.habits.v1"
        static let logs = "timebite.habitLogs.v1"
        static let records = "timebite.dailyTrackingRecords.v1"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func habits() throws -> [Habit] { try decode([Habit].self, forKey: Key.habits) ?? [] }
    func dailyRecords() throws -> [DailyTrackingRecord] { try decode([DailyTrackingRecord].self, forKey: Key.records) ?? [] }
    func habitLogs() throws -> [HabitLog] { try decode([HabitLog].self, forKey: Key.logs) ?? [] }

    func save(_ habit: Habit) throws {
        var values = try habits()
        if let index = values.firstIndex(where: { $0.id == habit.id }) { values[index] = habit } else { values.append(habit) }
        try encode(values, forKey: Key.habits)
    }

    func save(_ log: HabitLog) throws {
        var values = try habitLogs()
        if let index = values.firstIndex(where: { $0.id == log.id }) { values[index] = log } else { values.append(log) }
        try encode(values, forKey: Key.logs)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try decoder.decode(type, from: data)
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) throws {
        defaults.set(try encoder.encode(value), forKey: key)
    }
}
