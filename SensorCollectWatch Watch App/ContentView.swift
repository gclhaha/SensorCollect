//
//  ContentView.swift
//  SensorCollectWatch Watch App
//
//  Created by gclhaha on 2024/7/2.
//

import SwiftUI
import WatchConnectivity
import CoreMotion
import WatchKit

struct ContentView: View {
    @State private var timerRunning = false
    @State private var timeElapsed: TimeInterval = 0
    @State private var timer: Timer? = nil
    @StateObject private var sessionDelegate = WatchSessionDelegate()
    @StateObject private var motionManager = MotionManager()
    @StateObject private var workoutManager = WorkoutManager()
    @State private var timeFormatter = ElapsedTimeFormatter()
    var showSubseconds: Bool = true

    
    var body: some View {
        VStack {
            Text(NSNumber(value: timeElapsed), formatter: timeFormatter)
                .font(.title)
                .fontWeight(.semibold)
            
            Button(action: {
                if timerRunning {
                    pauseTimer()
                } else {
                    startTimer()
                }
            }) {
                HStack {
                    Image(systemName: timerRunning ? "pause.circle" : "play.circle")
                    Text(timerRunning ? "暂停" : "开始")
                }
            }
            
            Button(action: {
                saveData()
                resetTimer()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("保存")
                }
            }
            .disabled(timeElapsed == 0 || timerRunning)
            
            Button(action: {
                resetTimer()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle")
                    Text("重置")
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
        workoutManager.startWorkout()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            timeElapsed += 0.01
        }
    }
    
    func pauseTimer() {
        timerRunning = false
        motionManager.stopUpdates()
        workoutManager.stopWorkout()
        timer?.invalidate()
        timer = nil
    }
    
    func saveData() {
        if WCSession.default.isReachable {
            let sensorData = motionManager.collectData()
            let timestamp = getCurrentTimestamp()
            
            let chunkSize = 50
            let chunks = stride(from: 0, to: sensorData.count, by: chunkSize).map {
                Array(sensorData[$0..<min($0 + chunkSize, sensorData.count)])
            }
            
            for chunk in chunks {
                let message: [String: Any] = ["timestamp": timestamp, "data": chunk]
                WCSession.default.transferUserInfo(message)
            }
        }
    }
    
    func resetTimer() {
        timerRunning = false
        motionManager.stopUpdates()
        workoutManager.stopWorkout()
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

class ElapsedTimeFormatter: Formatter {
    let componentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    var showSubseconds = true

    override func string(for value: Any?) -> String? {
        guard let time = value as? TimeInterval else {
            return nil
        }

        guard let formattedString = componentsFormatter.string(from: time) else {
            return nil
        }

        if showSubseconds {
            let hundredths = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
            let decimalSeparator = Locale.current.decimalSeparator ?? "."
            return String(format: "%@%@%0.2d", formattedString, decimalSeparator, hundredths)
        }

        return formattedString
    }
}

#Preview {
    ContentView()
}
