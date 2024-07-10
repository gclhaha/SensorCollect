//
//  Untitled.swift
//  SensorCollect
//
//  Created by gclhaha on 2024/7/10.
//

import SwiftUI
import WatchConnectivity
import CoreMotion
import WatchKit


class WatchSessionDelegate: NSObject, ObservableObject, WCSessionDelegate {
    func activateSession() {
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
}
