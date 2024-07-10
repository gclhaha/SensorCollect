//
//  WatchSessionManager.swift
//  SensorCollect
//
//  Created by gclhaha on 2024/7/10.
//

import SwiftUI
import WatchConnectivity
import UniformTypeIdentifiers

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    @Published var savedData: [String: [[String: Any]]] = [:]
    
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
            if let timestamp = message["timestamp"] as? String, let sensorData = message["data"] as? [[String: Any]] {
                if self.savedData[timestamp] != nil {
                    self.savedData[timestamp]?.append(contentsOf: sensorData)
                } else {
                    self.savedData[timestamp] = sensorData
                }
            }
        }
    }
}
