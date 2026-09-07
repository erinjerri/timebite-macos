import Foundation

struct GoalCategory: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var colorToken: NowAllocationColorToken
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        colorToken: NowAllocationColorToken = .violet,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.colorToken = colorToken
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, colorToken, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        colorToken = try container.decodeIfPresent(NowAllocationColorToken.self, forKey: .colorToken) ?? .violet
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

final class LocalGoalCategoryStore {
    private static let key = "timebite.goalCategories.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [GoalCategory] {
        guard let data = defaults.data(forKey: Self.key),
              let categories = try? decoder.decode([GoalCategory].self, from: data) else {
            return Self.defaultCategories
        }
        return categories
    }

    func save(_ categories: [GoalCategory]) {
        defaults.set(try? encoder.encode(categories), forKey: Self.key)
    }

    private static let defaultCategories = [
        GoalCategory(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!, title: "Professional / Work / Career"),
        GoalCategory(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!, title: "Fitness"),
        GoalCategory(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000003")!, title: "Personal"),
        GoalCategory(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000004")!, title: "Learning")
    ]
}
