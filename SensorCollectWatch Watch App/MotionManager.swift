// MotionManager1.swift
// SensorCollect

import SwiftUI
import WatchConnectivity
import CoreMotion
import WatchKit

class MotionManager: NSObject, ObservableObject {
    private var motionManager = CMMotionManager()
    private var queue = OperationQueue()
    private var sensorData: [[String: Any]] = []
    private var currentTime: Double = 0.0
    private var baseTimestamp: Date = Date()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    func startUpdates(timeElapsed: Double) {
        currentTime = timeElapsed
        baseTimestamp = Date() // Reset base timestamp when updates start

        if motionManager.isDeviceMotionAvailable {
            print("sensor data is collecting")
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: queue) { (data, error) in
                if let data = data {
                    let elapsedMilliseconds = Int(self.currentTime * 1000) % 1000
                    let formattedTimestamp = self.dateFormatter.string(from: self.baseTimestamp) + String(format: ".%03d", elapsedMilliseconds)
                    
                    let sensorEntry: [String: Any] = [
                        "time": self.currentTime,
                        "timestamp": formattedTimestamp,
                        "accelerationX": data.userAcceleration.x,
                        "accelerationY": data.userAcceleration.y,
                        "accelerationZ": data.userAcceleration.z,
                        "rotationRateX": data.rotationRate.x,
                        "rotationRateY": data.rotationRate.y,
                        "rotationRateZ": data.rotationRate.z,
                        "gravityX": data.gravity.x,
                        "gravityY": data.gravity.y,
                        "gravityZ": data.gravity.z,
                        "pitch": data.attitude.pitch,
                        "roll": data.attitude.roll,
                        "yaw": data.attitude.yaw
                    ]
                    self.sensorData.append(sensorEntry)
                    self.currentTime += 0.01
                }
            }
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    func collectData() -> [[String: Any]] {
        let collectedData = sensorData
        sensorData.removeAll()
        return collectedData
    }
}
