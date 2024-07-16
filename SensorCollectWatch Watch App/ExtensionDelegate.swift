//  ExtensionDelegate.swift
//  SensorCollect
//
//  Created by gclhaha on 2024/7/11.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate, ObservableObject {
    func applicationDidFinishLaunching() {
        activateSession()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused or not yet started while the app was inactive.
    }

    func applicationWillResignActive() {
        // Pause ongoing tasks and disable timers.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let connectivityTask = task as? WKWatchConnectivityRefreshBackgroundTask {
                handleWatchConnectivityRefreshBackgroundTask(connectivityTask)
            } else if let refreshTask = task as? WKApplicationRefreshBackgroundTask {
                refreshTask.setTaskCompletedWithSnapshot(false)
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    private func handleWatchConnectivityRefreshBackgroundTask(_ task: WKWatchConnectivityRefreshBackgroundTask) {
        if WCSession.default.hasContentPending {
            // Wait for all data to be received
        } else {
            task.setTaskCompletedWithSnapshot(false)
        }
    }

    private func activateSession() {
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

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        print("Received user info: \(userInfo)")
    }
}
