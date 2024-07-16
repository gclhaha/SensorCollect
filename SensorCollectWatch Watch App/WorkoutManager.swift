//
//  WorkoutManager.swift
//  SensorCollect
//
//  Created by gclhaha on 2024/7/12.
//


import HealthKit
import WatchKit

class WorkoutManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        
    }
    
    var healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    @Published var isRunning = false

    override init() {
        super.init()
        requestAuthorization()
    }

    func requestAuthorization() {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
//        let typesToRead: Set = [
//            HKQuantityType.workoutType(),
//            HKQuantityType.quantityType(forIdentifier: .heartRate)!
//        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: []) { (success, error) in
            if !success {
                print("HealthKit authorization failed: \(String(describing: error?.localizedDescription))")
            }
        }
    }

    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("Unable to create workout session: \(error.localizedDescription)")
            return
        }
        
        session?.delegate = self
        builder?.delegate = self

        let startDate = Date()
        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            if !success {
                print("Error starting collection: \(String(describing: error?.localizedDescription))")
            }
        }
        
        isRunning = true
    }

    func stopWorkout() {
        session?.end()
        isRunning = false
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Handle state changes
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle collected events
    }
}
