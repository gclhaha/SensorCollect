//
//  WatchSessionManager.swift
//  SensorCollect
//
//  Created by gclhaha on 2024/7/5.
//

import SwiftUI
import WatchConnectivity
import CoreData

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    @Published var savedData: [String: [[String: Double]]] = [:]
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            let context = CoreDataManager.shared.persistentContainer.viewContext
            
            for (timestamp, data) in message {
                if let sensorData = data as? [[String: Double]] {
                    for dataPoint in sensorData {
                        let entity = SensorData(context: context)
                        entity.timestamp = timestamp
                        entity.time = dataPoint["time"] ?? 0.0
                        entity.accelerationX = dataPoint["accelerationX"] ?? 0.0
                        entity.accelerationY = dataPoint["accelerationY"] ?? 0.0
                        entity.accelerationZ = dataPoint["accelerationZ"] ?? 0.0
                        entity.rotationRateX = dataPoint["rotationRateX"] ?? 0.0
                        entity.rotationRateY = dataPoint["rotationRateY"] ?? 0.0
                        entity.rotationRateZ = dataPoint["rotationRateZ"] ?? 0.0
                        entity.gravityX = dataPoint["gravityX"] ?? 0.0
                        entity.gravityY = dataPoint["gravityY"] ?? 0.0
                        entity.gravityZ = dataPoint["gravityZ"] ?? 0.0
                        entity.pitch = dataPoint["pitch"] ?? 0.0
                        entity.roll = dataPoint["roll"] ?? 0.0
                        entity.yaw = dataPoint["yaw"] ?? 0.0
                    }
                    CoreDataManager.shared.saveContext()
                }
            }
        }
    }
}
