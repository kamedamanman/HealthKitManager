import Foundation
import HealthKit

public class HealthKitManager {
    private let healthStore = HKHealthStore()

    public init() {}

    public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.example.HealthKitHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }

        guard let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(false, NSError(domain: "com.example.HealthKitHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Step count is not available."]))
            return
        }

        healthStore.requestAuthorization(toShare: [], read: [stepsQuantityType]) { success, error in
            completion(success, error)
        }
    }

    public func fetchSteps(completion: @escaping (Double?, Error?) -> Void) {
        guard let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, NSError(domain: "com.example.HealthKitHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Step count is not available."]))
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
            guard error == nil else {
                completion(nil, error)
                return
            }

            if let sum = statistics?.sumQuantity() {
                let steps = sum.doubleValue(for: HKUnit.count())
                completion(steps, nil)
            } else {
                completion(nil, nil)
            }
        }

        healthStore.execute(query)
    }
}
