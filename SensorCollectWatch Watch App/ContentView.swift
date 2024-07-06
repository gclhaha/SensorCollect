//
//  ContentView.swift
//  SensorCollectWatch Watch App
//
//  Created by gclhaha on 2024/7/2.
//

import SwiftUI
import WatchConnectivity
import CoreMotion

struct ContentView: View {
    @State private var timerRunning = false
    @State private var timeElapsed: Double = 0.0
    @State private var timer: Timer? = nil
    @StateObject private var sessionDelegate = WatchSessionDelegate()
    @StateObject private var motionManager = MotionManager()
    
    var body: some View {
        VStack {
            Text(String(format: "%.2f", timeElapsed))
                .font(.largeTitle)
            
            Button(action: {
                if timerRunning {
                    pauseTimer()
                } else {
                    startTimer()
                }
            }) {
                HStack {
                    Image(systemName: timerRunning ? "pause.circle" : "play.circle")
                    Text(timerRunning ? "Pause" : "Start")
                }
            }
            
            Button(action: {
                saveData()
                resetTimer()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save")
                }
            }
            .disabled(timeElapsed == 0 || timerRunning)
            
            Button(action: {
                resetTimer()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle")
                    Text("Reset")
                }
            }
            .disabled(timeElapsed == 0 || timerRunning)
        }
        .onAppear {
            sessionDelegate.activateSession()
        }
    }
    
    func startTimer() {
        timerRunning = true
        motionManager.startUpdates(timeElapsed: timeElapsed)
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            timeElapsed += 0.01
        }
    }
    
    func pauseTimer() {
        timerRunning = false
        motionManager.stopUpdates()
        timer?.invalidate()
        timer = nil
    }
    
    func saveData() {
        if WCSession.default.isReachable {
            let sensorData = motionManager.collectData()
            let timestamp = getCurrentTimestamp()
            sendSensorDataInChunks(sensorData, timestamp: timestamp)
        }
    }
    
    func resetTimer() {
        timerRunning = false
        motionManager.stopUpdates()
        timer?.invalidate()
        timer = nil
        timeElapsed = 0.0
    }
    
    func getCurrentTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: Date())
    }
    
    func sendSensorDataInChunks(_ sensorData: [[String: Double]], timestamp: String) {
        let chunkSize = 100 // 每次发送100条数据
        var chunkedData: [[String: Double]] = []
        
        for (index, dataPoint) in sensorData.enumerated() {
            chunkedData.append(dataPoint)
            if chunkedData.count == chunkSize || index == sensorData.count - 1 {
                let message: [String: Any] = ["timestamp": timestamp, "data": chunkedData]
                WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
                chunkedData.removeAll()
            }
        }
    }
}

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

class MotionManager: NSObject, ObservableObject {
    private var motionManager = CMMotionManager()
    private var queue = OperationQueue()
    private var sensorData: [[String: Double]] = []
    private var currentTime: Double = 0.0

    func startUpdates(timeElapsed: Double) {
        currentTime = timeElapsed
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: queue) { (data, error) in
                if let data = data {
                    let sensorEntry: [String: Double] = [
                        "time": self.currentTime,
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

    func collectData() -> [[String: Double]] {
        let collectedData = sensorData
        sensorData.removeAll()
        return collectedData
    }
}

#Preview {
    ContentView()
}
