import Foundation
import Combine
#if canImport(HealthKit)
import HealthKit
#endif

struct HealthSnapshot: Codable, Equatable, Sendable {
    var stepsToday: Int
    var activeEnergyKilocalories: Double?
    var sleepMinutes: Int?
}

struct HealthSnapshotState: Codable, Sendable {
    var snapshot: HealthSnapshot?
    var message: String?
    var updatedAt: Date
}

final class LocalHealthSnapshotStore {
    private static let key = "timebite.healthSnapshot.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> HealthSnapshotState? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? decoder.decode(HealthSnapshotState.self, from: data)
    }

    func save(snapshot: HealthSnapshot?, message: String?) {
        let state = HealthSnapshotState(snapshot: snapshot, message: message, updatedAt: Date())
        defaults.set(try? encoder.encode(state), forKey: Self.key)
    }
}

final class HealthDataService: ObservableObject {
    static let shared = HealthDataService()

    @Published private(set) var snapshot: HealthSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var message: String?

    private let store: LocalHealthSnapshotStore

    init(store: LocalHealthSnapshotStore = LocalHealthSnapshotStore()) {
        self.store = store
        if let cached = store.load() {
            snapshot = cached.snapshot
            message = cached.message
        }
    }

    var isAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    func connectAndRefresh(includeSleep: Bool = true, includeFitness: Bool = true) {
        #if canImport(HealthKit)
        guard includeSleep || includeFitness else {
            isLoading = false
            message = "Choose sleep or fitness data to connect."
            store.save(snapshot: snapshot, message: message)
            return
        }
        guard HKHealthStore.isHealthDataAvailable() else {
            isLoading = false
            message = "Health data is not available on this Mac. A companion sync source can still surface a cached snapshot here."
            store.save(snapshot: snapshot, message: message)
            return
        }
        isLoading = true
        message = "Requesting Health permission..."
        let healthStore = HKHealthStore()
        let steps = includeFitness ? HKObjectType.quantityType(forIdentifier: .stepCount) : nil
        let activeEnergy = includeFitness ? HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) : nil
        let sleep = includeSleep ? HKObjectType.categoryType(forIdentifier: .sleepAnalysis) : nil

        var readTypes = Set<HKObjectType>()
        if let steps { readTypes.insert(steps) }
        if let activeEnergy { readTypes.insert(activeEnergy) }
        if let sleep { readTypes.insert(sleep) }

        guard !readTypes.isEmpty else {
            isLoading = false
            message = "HealthKit data types were unavailable."
            store.save(snapshot: snapshot, message: message)
            return
        }

        healthStore.requestAuthorization(toShare: [], read: readTypes) { [weak self] success, error in
            let currentSelf = self
            Task { @MainActor in
                guard let currentSelf else { return }
                guard success, error == nil else {
                    currentSelf.isLoading = false
                    currentSelf.message = "Health permission was not granted."
                    currentSelf.store.save(snapshot: currentSelf.snapshot, message: currentSelf.message)
                    return
                }
                currentSelf.fetchSnapshot(
                    using: healthStore,
                    includeSleep: includeSleep,
                    includeFitness: includeFitness,
                    stepsType: steps,
                    activeEnergyType: activeEnergy,
                    sleepType: sleep
                )
            }
        }
        #else
        message = "HealthKit sync is available to an iPhone companion app. This Mac app can show the synced snapshot when that bridge is connected."
        store.save(snapshot: snapshot, message: message)
        #endif
    }

    #if canImport(HealthKit)
    private func fetchSnapshot(
        using store: HKHealthStore,
        includeSleep: Bool,
        includeFitness: Bool,
        stepsType: HKQuantityType?,
        activeEnergyType: HKQuantityType?,
        sleepType: HKCategoryType?
    ) {
        let group = DispatchGroup()
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let sleepStart = now.addingTimeInterval(-24 * 60 * 60)

        var stepsToday = snapshot?.stepsToday ?? 0
        var activeEnergyKilocalories = snapshot?.activeEnergyKilocalories
        var sleepMinutes = snapshot?.sleepMinutes

        if includeFitness {
            guard let stepsType, let activeEnergyType else {
                isLoading = false
                message = "HealthKit data types were unavailable."
                self.store.save(snapshot: snapshot, message: message)
                return
            }

            group.enter()
            fetchQuantity(
                using: store,
                type: stepsType,
                unit: .count(),
                start: startOfDay,
                end: now
            ) { value in
                stepsToday = Int(value ?? 0)
                group.leave()
            }

            group.enter()
            fetchQuantity(
                using: store,
                type: activeEnergyType,
                unit: .kilocalorie(),
                start: startOfDay,
                end: now
            ) { value in
                activeEnergyKilocalories = value
                group.leave()
            }
        }

        if includeSleep {
            guard let sleepType else {
                isLoading = false
                message = "HealthKit data types were unavailable."
                self.store.save(snapshot: snapshot, message: message)
                return
            }

            group.enter()
            fetchSleepMinutes(
                using: store,
                type: sleepType,
                start: sleepStart,
                end: now
            ) { value in
                sleepMinutes = value
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.snapshot = HealthSnapshot(
                stepsToday: stepsToday,
                activeEnergyKilocalories: activeEnergyKilocalories,
                sleepMinutes: sleepMinutes
            )
            self.isLoading = false

            var parts: [String] = []
            parts.append("Synced \(stepsToday) steps")
            if let activeEnergyKilocalories {
                parts.append(String(format: "%.0f active calories", activeEnergyKilocalories))
            }
            if let sleepMinutes {
                parts.append("\(sleepMinutes) minutes of sleep")
            }
            self.message = parts.isEmpty ? "Health data is connected." : parts.joined(separator: " · ")
            self.store.save(snapshot: self.snapshot, message: self.message)
        }
    }

    private func fetchQuantity(
        using store: HKHealthStore,
        type: HKQuantityType,
        unit: HKUnit,
        start: Date,
        end: Date,
        completion: @escaping (Double?) -> Void
    ) {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, _ in
            DispatchQueue.main.async {
                completion(statistics?.sumQuantity()?.doubleValue(for: unit))
            }
        }
        store.execute(query)
    }

    private func fetchSleepMinutes(
        using store: HKHealthStore,
        type: HKCategoryType,
        start: Date,
        end: Date,
        completion: @escaping (Int?) -> Void
    ) {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            let sleepSamples = (samples as? [HKCategorySample]) ?? []
            let minutes = sleepSamples.reduce(into: 0) { total, sample in
                guard sample.value != HKCategoryValueSleepAnalysis.awake.rawValue,
                      sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue else {
                    return
                }
                total += Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
            }
            DispatchQueue.main.async {
                completion(minutes > 0 ? minutes : nil)
            }
        }
        store.execute(query)
    }
    #endif
}
