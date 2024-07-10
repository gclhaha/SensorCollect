//
//  MotionManager.swift
//  SensorCollect
//
//  Created by gclhaha on 2024/7/10.
//

import SwiftUI
import WatchConnectivity
import CoreMotion
import WatchKit

class MotionManager: NSObject, ObservableObject {
    private var motionManager = CMMotionManager()
    private var queue = OperationQueue()
    private var sensorData: [[String: Any]] = []
    private var currentTime: Double = 0.0

    func startUpdates(timeElapsed: Double) {
        currentTime = timeElapsed
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: queue) { (data, error) in
                if let data = data {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                    let timestamp = dateFormatter.string(from: Date())
                    
                    let sensorEntry: [String: Any] = [
                        "time": self.currentTime,
                        "timestamp": timestamp,
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
                    print(sensorEntry)
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
